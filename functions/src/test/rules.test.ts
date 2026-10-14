import "./setup";

import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import {
  RulesTestEnvironment, assertFails, assertSucceeds, initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from "firebase/firestore";
import { getBytes, ref, uploadBytes } from "firebase/storage";

import { PROJECT } from "./setup";

const root = resolve(__dirname, "../../..");
let env: RulesTestEnvironment;

const [fsHost, fsPort] = (process.env.FIRESTORE_EMULATOR_HOST ?? "127.0.0.1:8080").split(":");
const [stHost, stPort] = (process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? "127.0.0.1:9199").split(":");

describe("security rules", () => {
  before(async () => {
    env = await initializeTestEnvironment({
      projectId: PROJECT,
      firestore: { rules: readFileSync(`${root}/firestore.rules`, "utf8"), host: fsHost, port: Number(fsPort) },
      storage: { rules: readFileSync(`${root}/storage.rules`, "utf8"), host: stHost, port: Number(stPort) },
    });
  });

  after(async () => env.cleanup());

  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, "users/alice"), { displayName: "Alice", receiptCounter: 3, status: "active" });
      await setDoc(doc(db, "users/alice/receipts/r1"), { number: "HV-000001", shop: "Currys", totalMinor: 100 });
      await setDoc(doc(db, "users/alice/items/i1"), { name: "TV", receiptId: "r1", type: "physical" });
      await setDoc(doc(db, "users/alice/stats/spending"), { lifetime: { GBP: 100 } });
      await setDoc(doc(db, "users/alice/warranties/i1"), { endDate: "2028-09-12" });
    });
  });

  const alice = () => env.authenticatedContext("alice").firestore();
  const bob = () => env.authenticatedContext("bob").firestore();
  const anon = () => env.unauthenticatedContext().firestore();

  it("lets the owner read their own data", async () => {
    await assertSucceeds(getDoc(doc(alice(), "users/alice/receipts/r1")));
    await assertSucceeds(getDoc(doc(alice(), "users/alice/items/i1")));
    await assertSucceeds(getDoc(doc(alice(), "users/alice/stats/spending")));
  });

  it("stops a second user reading or writing the first user's data", async () => {
    await assertFails(getDoc(doc(bob(), "users/alice")));
    await assertFails(getDoc(doc(bob(), "users/alice/receipts/r1")));
    await assertFails(getDoc(doc(bob(), "users/alice/items/i1")));
    await assertFails(setDoc(doc(bob(), "users/alice/items/guess"), { name: "x", estimated: true }));
    await assertFails(updateDoc(doc(bob(), "users/alice/receipts/r1"), { shop: "Argos" }));
  });

  it("denies signed-out access", async () => {
    await assertFails(getDoc(doc(anon(), "users/alice/receipts/r1")));
    await assertFails(setDoc(doc(anon(), "users/x"), { displayName: "x" }));
  });

  it("never lets clients write receipt numbers, counters or totals", async () => {
    await assertFails(updateDoc(doc(alice(), "users/alice"), { receiptCounter: 99 }));
    await assertFails(setDoc(doc(alice(), "users/alice/receipts/new"), { number: "HV-999999" }));
    await assertFails(updateDoc(doc(alice(), "users/alice/receipts/r1"), { number: "HV-000002" }));
    await assertFails(setDoc(doc(alice(), "users/alice/stats/spending"), { lifetime: { GBP: 1 } }));
    await assertFails(getDoc(doc(alice(), "users/alice/saveKeys/k")));
    await assertSucceeds(updateDoc(doc(alice(), "users/alice/receipts/r1"), { shop: "Currys PC World", totalMinor: 200 }));
  });

  it("lets the owner update their profile settings only", async () => {
    await assertSucceeds(updateDoc(doc(alice(), "users/alice"), { reminderMinutes: 600, mainCurrency: "EUR" }));
    await assertFails(updateDoc(doc(alice(), "users/alice"), { mainCurrency: "BTC" }));
    await assertFails(updateDoc(doc(alice(), "users/alice"), { status: "deleted" }));
    await assertSucceeds(setDoc(doc(env.authenticatedContext("carol").firestore(), "users/carol"), {
      displayName: "Carol", timezone: "Europe/London",
    }));
    await assertFails(setDoc(doc(env.authenticatedContext("dave").firestore(), "users/dave"), { receiptCounter: 5 }));
  });

  it("allows belongings without a receipt but not fake receipt links", async () => {
    await assertSucceeds(setDoc(doc(alice(), "users/alice/items/old1"), {
      name: "Oak sideboard", type: "physical", estimated: true, inHome: true,
      allocations: { dining: 1 }, roomIds: ["dining"], quantity: 1, lineTotalMinor: 65000, currency: "GBP",
    }));
    await assertFails(setDoc(doc(alice(), "users/alice/items/old2"), {
      name: "Fake", estimated: true, receiptId: "r1",
    }));
    await assertFails(updateDoc(doc(alice(), "users/alice/items/i1"), { receiptId: "other" }));
    await assertFails(updateDoc(doc(alice(), "users/alice/items/i1"), { photoCount: 9 }));
    await assertSucceeds(updateDoc(doc(alice(), "users/alice/items/i1"), { status: "sold", highValue: true }));
    await assertFails(updateDoc(doc(alice(), "users/alice/items/i1"), { status: "stolen" }));
    await assertFails(deleteDoc(doc(alice(), "users/alice/items/i1")));
  });

  it("keeps photo upload times and thumbnails server-only", async () => {
    const good = {
      path: "users/alice/items/i1/photos/p1.jpg", source: "camera", sha256: "a".repeat(64), gpsKept: false,
    };
    await assertSucceeds(setDoc(doc(alice(), "users/alice/items/i1/photos/p1"), good));
    await assertFails(setDoc(doc(alice(), "users/alice/items/i1/photos/p2"), { ...good, path: "users/alice/items/i1/photos/p2.jpg", serverUploadedAt: new Date() }));
    await assertFails(setDoc(doc(alice(), "users/alice/items/i1/photos/p3"), { ...good, path: "users/bob/x.jpg" }));
    await assertSucceeds(updateDoc(doc(alice(), "users/alice/items/i1/photos/p1"), { label: "Serial label" }));
    await assertFails(updateDoc(doc(alice(), "users/alice/items/i1/photos/p1"), { sha256: "b".repeat(64) }));
  });

  it("lets Functions alone schedule reminders and fill exports", async () => {
    await assertSucceeds(setDoc(doc(alice(), "users/alice/warranties/i1"), { endDate: "2029-01-01", remind3Months: true }));
    await assertFails(updateDoc(doc(alice(), "users/alice/warranties/i1"), { nextReminderAt: new Date() }));
    await assertFails(setDoc(doc(alice(), "users/alice/warranties/i2"), { endDate: "soon" }));
    await assertSucceeds(setDoc(doc(alice(), "users/alice/returns/r1"), { deadline: "2026-10-12", sourceText: "30 days" }));
    await assertSucceeds(setDoc(doc(alice(), "users/alice/exports/e1"), { kind: "inventory", format: "pdf", status: "building" }));
    await assertFails(setDoc(doc(alice(), "users/alice/exports/e2"), { kind: "inventory", format: "pdf", status: "ready", url: "x" }));
    await assertFails(updateDoc(doc(alice(), "users/alice/exports/e1"), { status: "ready" }));
  });

  describe("storage", () => {
    const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
    const meta = { contentType: "image/jpeg" };

    it("keeps files private to their owner", async () => {
      const a = env.authenticatedContext("alice").storage();
      const b = env.authenticatedContext("bob").storage();
      await assertSucceeds(uploadBytes(ref(a, "users/alice/receipts/new1/original-1.jpg"), jpeg, meta));
      await assertSucceeds(getBytes(ref(a, "users/alice/receipts/new1/original-1.jpg")));
      await assertFails(getBytes(ref(b, "users/alice/receipts/new1/original-1.jpg")));
      await assertFails(uploadBytes(ref(b, "users/alice/receipts/new2/original-1.jpg"), jpeg, meta));
    });

    it("freezes originals once the receipt is saved", async () => {
      const a = env.authenticatedContext("alice").storage();
      await assertFails(uploadBytes(ref(a, "users/alice/receipts/r1/original-1.jpg"), jpeg, meta));
    });

    it("blocks client writes to exports, thumbnails and odd paths", async () => {
      const a = env.authenticatedContext("alice").storage();
      await assertFails(uploadBytes(ref(a, "users/alice/exports/e1.pdf"), jpeg, { contentType: "application/pdf" }));
      await assertFails(uploadBytes(ref(a, "users/alice/items/i1/photos/thumbs/p1.jpg"), jpeg, meta));
      await assertFails(uploadBytes(ref(a, "users/alice/receipts/new3/script.js"), jpeg, { contentType: "text/javascript" }));
      await assertSucceeds(uploadBytes(ref(a, "users/alice/items/i1/photos/p1.jpg"), jpeg, meta));
      await assertFails(uploadBytes(ref(a, "users/alice/items/i1/photos/p1.jpg"), jpeg, meta));
    });

    it("denies signed-out access", async () => {
      const s = env.unauthenticatedContext().storage();
      await assertFails(getBytes(ref(s, "users/alice/receipts/new1/original-1.jpg")));
    });
  });
});
