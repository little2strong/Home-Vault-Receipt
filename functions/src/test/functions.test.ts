import "./setup";

import assert from "node:assert/strict";

import { DateTime } from "luxon";

import { createProfile, deleteAccountData } from "../account";
import { Timestamp, bucket, db } from "../common";
import { buildExport, inventoryCsv, inventoryRows } from "../exports";
import { saveReceiptFor } from "../receipts";
import { localInstant, returnReminders, sendDueReminders, settingsFrom, warrantyReminders } from "../reminders";
import { computeStats, recomputeStats } from "../stats";
import { clearFirestore } from "./setup";

const UID = "alice";

const item = (n: number) => ({
  name: `Item ${n}`,
  category: "electronics",
  type: "physical",
  purpose: "home",
  inHome: true,
  allocations: { room1: 1 },
  quantity: 1,
  unitPriceMinor: 100 * n,
  lineTotalMinor: 100 * n,
});

describe("saveReceipt", () => {
  beforeEach(async () => {
    await clearFirestore();
    await createProfile(UID, "alice@example.com", "Alice");
  });

  it("writes one receipt and twelve items with one HV number", async () => {
    const res = await saveReceiptFor(UID, {
      saveKey: "key-0000-0001",
      receiptId: "rcpt1",
      receipt: { shop: "Currys", purchaseDate: "2026-09-12", currency: "GBP", totalMinor: 7800, source: "camera" },
      items: Array.from({ length: 12 }, (_, i) => item(i + 1)),
    });
    assert.equal(res.number, "HV-000001");
    assert.equal(res.itemIds.length, 12);
    const receipts = await db.collection(`users/${UID}/receipts`).get();
    const items = await db.collection(`users/${UID}/items`).get();
    assert.equal(receipts.size, 1);
    assert.equal(items.size, 12);
    const first = items.docs.find((d) => d.id === "rcpt1-0")!.data();
    assert.equal(first.receiptNumber, "HV-000001");
    assert.equal(first.shop, "Currys");
    assert.ok(first.searchTokens.includes("cur"));
    assert.deepEqual(first.roomIds, ["room1"]);
  });

  it("ignores repeated taps and retries with the same saveKey", async () => {
    const req = {
      saveKey: "key-0000-0002",
      receiptId: "rcpt2",
      receipt: { shop: "IKEA", purchaseDate: "2026-09-08", totalMinor: 4800 },
      items: [item(1)],
    };
    const results = await Promise.all([1, 2, 3, 4, 5].map(() => saveReceiptFor(UID, req)));
    assert.equal(new Set(results.map((r) => r.number)).size, 1);
    assert.equal((await db.collection(`users/${UID}/receipts`).get()).size, 1);
    assert.equal((await db.collection(`users/${UID}/items`).get()).size, 1);
    const again = await saveReceiptFor(UID, req);
    assert.equal(again.alreadySaved, true);
  });

  it("numbers receipts in order", async () => {
    const a = await saveReceiptFor(UID, { saveKey: "key-a-000001", receiptId: "ra", receipt: {}, items: [] });
    const b = await saveReceiptFor(UID, { saveKey: "key-b-000001", receiptId: "rb", receipt: {}, items: [] });
    assert.equal(a.number, "HV-000001");
    assert.equal(b.number, "HV-000002");
  });

  it("keeps unknown values empty rather than inventing them", async () => {
    await saveReceiptFor(UID, { saveKey: "key-c-000001", receiptId: "rc", receipt: {}, items: [] });
    const r = (await db.doc(`users/${UID}/receipts/rc`).get()).data()!;
    assert.equal(r.shop, null);
    assert.equal(r.purchaseDate, null);
    assert.equal(r.totalMinor, null);
  });

  it("refuses an original that has not uploaded", async () => {
    await assert.rejects(
      saveReceiptFor(UID, {
        saveKey: "key-d-000001",
        receiptId: "rd",
        receipt: { originalPaths: [`users/${UID}/receipts/rd/original-1.jpg`] },
        items: [],
      }),
      /not finished uploading/,
    );
  });

  it("refuses originals outside the receipt folder", async () => {
    await assert.rejects(
      saveReceiptFor(UID, {
        saveKey: "key-e-000001",
        receiptId: "re",
        receipt: { originalPaths: ["users/bob/receipts/x/original-1.jpg"] },
        items: [],
      }),
      /not in this receipt/,
    );
  });

  it("accepts an uploaded original", async () => {
    const path = `users/${UID}/receipts/rf/original-1.jpg`;
    await bucket().file(path).save(Buffer.from("jpeg"), { contentType: "image/jpeg", resumable: false });
    const res = await saveReceiptFor(UID, {
      saveKey: "key-f-000001",
      receiptId: "rf",
      receipt: { originalPaths: [path], originalTypes: ["image/jpeg"] },
      items: [item(1)],
    });
    assert.equal(res.alreadySaved, false);
  });
});

describe("spending stats", () => {
  it("totals per currency from confirmed receipts, by window", () => {
    const s = computeStats(
      [
        { totalMinor: 1000, currency: "GBP", purchaseDate: "2026-10-01" },
        { totalMinor: 500, currency: "GBP", purchaseDate: "2026-03-01" },
        { totalMinor: 250, currency: "GBP", purchaseDate: "2024-01-01" },
        { totalMinor: 8650, currency: "EUR", purchaseDate: "2026-09-20" },
        { totalMinor: null, currency: "GBP", purchaseDate: "2026-10-02" },
      ],
      [
        { receiptId: "a", lineTotalMinor: 1000, currency: "GBP", purchaseDate: "2026-10-01", category: "electronics", purpose: "home" },
        { receiptId: "b", lineTotalMinor: 500, currency: "GBP", purchaseDate: "2026-03-01", category: "car", purpose: "car", carId: "golf" },
        { receiptId: null, lineTotalMinor: 9999, currency: "GBP", purchaseDate: "2026-10-01", category: "other" },
      ],
      "2026-10-06",
    );
    assert.deepEqual(s.last30Days, { GBP: 1000, EUR: 8650 });
    assert.deepEqual(s.last365Days, { GBP: 1500, EUR: 8650 });
    assert.deepEqual(s.lifetime, { GBP: 1750, EUR: 8650 });
    assert.equal(s.receipts30, 3);
    assert.equal(s.receiptsLifetime, 5);
    assert.deepEqual(s.byCategory365.GBP, { electronics: 1000, car: 500 });
    assert.equal(s.cars.golf.itemCount, 1);
    assert.deepEqual(s.cars.golf.last365Days, { GBP: 500 });
    assert.equal(s.firstPurchase, "2024-01-01");
  });

  it("writes stats that match the receipts", async () => {
    await clearFirestore();
    await createProfile(UID);
    const today = DateTime.now().setZone("Europe/London").toISODate()!;
    await saveReceiptFor(UID, {
      saveKey: "key-s-000001", receiptId: "rs",
      receipt: { purchaseDate: today, totalMinor: 55398, currency: "GBP" },
      items: [item(1)],
    });
    await recomputeStats(UID);
    const s = (await db.doc(`users/${UID}/stats/spending`).get()).data()!;
    assert.equal(s.last30Days.GBP, 55398);
    assert.equal(s.receipts30, 1);
  });
});

describe("reminders", () => {
  const london = settingsFrom({ timezone: "Europe/London", reminderMinutes: 9 * 60 });

  it("fires at 09:00 local time either side of the clock change", () => {
    // 15 Aug is BST (UTC+1); 1 Nov is GMT.
    assert.equal(localInstant("2026-08-15", london).toUTC().toISO(), "2026-08-15T08:00:00.000Z");
    assert.equal(localInstant("2026-11-01", london).toUTC().toISO(), "2026-11-01T09:00:00.000Z");
  });

  it("schedules 3 months and 2 weeks before the end date", () => {
    const now = DateTime.fromISO("2026-01-01T00:00:00Z");
    const r = warrantyReminders("2026-11-15", london, { threeMonths: true, twoWeeks: true }, now);
    assert.deepEqual(r.map((x) => x.kind), ["3m", "2w"]);
    assert.equal(r[0].at.toDate().toISOString(), "2026-08-15T08:00:00.000Z");
    assert.equal(r[1].at.toDate().toISOString(), "2026-11-01T09:00:00.000Z");
  });

  it("skips reminders in the past and when switched off", () => {
    const now = DateTime.fromISO("2026-09-01T00:00:00Z");
    assert.deepEqual(
      warrantyReminders("2026-11-15", london, { threeMonths: true, twoWeeks: true }, now).map((x) => x.kind),
      ["2w"],
    );
    const off = settingsFrom({ warrantyReminders: false });
    assert.equal(warrantyReminders("2027-11-15", off, { threeMonths: true, twoWeeks: true }, now).length, 0);
  });

  it("uses the user's own timezone", () => {
    const ny = settingsFrom({ timezone: "America/New_York", reminderMinutes: 8 * 60 });
    assert.equal(localInstant("2026-07-01", ny).toUTC().toISO(), "2026-07-01T12:00:00.000Z");
  });

  it("reminds 7 days, 1 day and on the last day to return", () => {
    const r = returnReminders("2026-10-12", london, DateTime.fromISO("2026-09-12T00:00:00Z"));
    assert.deepEqual(r.map((x) => x.kind), ["7d", "1d", "0d"]);
  });

  it("advances the schedule after sending", async () => {
    await clearFirestore();
    const ref = db.doc(`users/${UID}/warranties/item1`);
    const past = Timestamp.fromMillis(Date.now() - 60_000);
    const future = Timestamp.fromMillis(Date.now() + 86_400_000);
    await ref.set({
      endDate: "2027-01-01",
      itemName: "TV",
      reminders: [{ kind: "3m", at: past }, { kind: "2w", at: future }],
      nextReminderAt: past,
    });
    await sendDueReminders();
    const d = (await ref.get()).data()!;
    assert.equal(d.reminders.length, 1);
    assert.equal(d.nextReminderAt.toMillis(), future.toMillis());
    assert.deepEqual(d.sentKinds, ["3m"]);
  });
});

describe("exports", () => {
  const vault = {
    profile: { displayName: "Sam" },
    receipts: [],
    cars: [],
    warranties: [],
    returns: [],
    rooms: [{ id: "bed", name: "Bedroom 1", order: 1 }, { id: "living", name: "Living room", order: 0 }],
    items: [
      { id: "lamp", name: "Table lamp, \"brass\"", type: "physical", inHome: true, status: "owned", quantity: 2,
        unitPriceMinor: 2400, lineTotalMinor: 4800, allocations: { bed: 1, living: 1 }, currency: "GBP", receiptId: "r", receiptNumber: "HV-000121" },
      { id: "print", name: "Framed print", type: "physical", inHome: true, status: "owned", quantity: 1,
        lineTotalMinor: 12000, allocations: { living: 1 }, currency: "GBP", estimated: true, yearBought: 2021 },
      { id: "sold", name: "Old sofa", type: "physical", inHome: true, status: "sold", quantity: 1, allocations: { living: 1 } },
      { id: "milk", name: "Milk", type: "consumable", inHome: false, quantity: 1 },
    ],
  };

  it("splits quantities across rooms and leaves out non-owned items", () => {
    const rows = inventoryRows(vault, {});
    assert.deepEqual(rows.map((r) => `${r.room}:${r.item.id}:${r.value}`), [
      "Living room:print:12000",
      "Living room:lamp:2400",
      "Bedroom 1:lamp:2400",
    ]);
  });

  it("escapes CSV and marks estimates", () => {
    const text = inventoryCsv(vault, {});
    assert.ok(text.includes('"Table lamp, ""brass"""'));
    assert.ok(text.includes("Estimate"));
    assert.ok(text.includes("About 2021"));
    assert.equal(inventoryCsv(vault, { includeWithoutReceipts: false }).includes("Framed print"), false);
  });

  it("builds a PDF inventory into private storage with a 24-hour link", async () => {
    await clearFirestore();
    await createProfile(UID, null, "Sam");
    await saveReceiptFor(UID, { saveKey: "key-x-000001", receiptId: "rx", receipt: {}, items: [item(3)] });
    const out = await buildExport(UID, "exp1", { kind: "inventory", format: "pdf", filters: { includePhotos: false } });
    assert.equal(out.status, "ready");
    assert.equal(out.path, `users/${UID}/exports/exp1.pdf`);
    const [exists] = await bucket().file(out.path).exists();
    assert.ok(exists);
    const hours = (out.expiresAt.toMillis() - Date.now()) / 3_600_000;
    assert.ok(hours > 23.9 && hours <= 24);
  });

  it("builds an everything ZIP", async () => {
    const out = await buildExport(UID, "exp2", { kind: "archive", format: "zip", filters: {} });
    assert.equal(out.path.endsWith(".zip"), true);
    assert.ok(out.sizeBytes > 100);
  });
});

describe("account deletion", () => {
  it("removes Firestore data and files", async () => {
    await clearFirestore();
    await createProfile(UID);
    await saveReceiptFor(UID, { saveKey: "key-z-000001", receiptId: "rz", receipt: {}, items: [item(1)] });
    await bucket().file(`users/${UID}/items/rz-0/photos/p.jpg`).save(Buffer.from("x"), { resumable: false });
    await deleteAccountData(UID);
    assert.equal((await db.doc(`users/${UID}`).get()).exists, false);
    assert.equal((await db.collection(`users/${UID}/items`).get()).size, 0);
    const [files] = await bucket().getFiles({ prefix: `users/${UID}/` });
    assert.equal(files.length, 0);
  });

  it("does not recreate spending stats for a deleted account", async () => {
    await clearFirestore();
    // Item and receipt triggers still fire after the profile is gone.
    await recomputeStats(UID);
    assert.equal((await db.doc(`users/${UID}/stats/spending`).get()).exists, false);
  });
});
