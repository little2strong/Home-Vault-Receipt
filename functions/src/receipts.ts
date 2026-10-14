import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  CATEGORIES, CATEGORY_LABELS, CURRENCIES, FieldValue, ITEM_TYPES, PURPOSES, SOURCES,
  bucket, db, int, isId, isoDate, oneOf, receiptNumber, requireUid, sameArray,
  searchTokens, str, userPath,
} from "./common";
import { deleteItemData } from "./items";
import { recomputeStats } from "./stats";

const MAX_ITEMS = 400;

export interface SaveRequest {
  saveKey?: unknown;
  receiptId?: unknown;
  receipt?: Record<string, unknown>;
  items?: unknown[];
}

export interface SaveResponse {
  receiptId: string;
  number: string;
  itemIds: string[];
  alreadySaved: boolean;
}

/** Validates and coerces one item from the client into confirmed values. */
export function cleanItem(raw: unknown) {
  const m = (raw ?? {}) as Record<string, unknown>;
  const type = oneOf(m.type, ITEM_TYPES, "physical");
  const physical = type === "physical";
  const quantity = int(m.quantity, 1, 9999) ?? 1;
  const allocations: Record<string, number> = {};
  if (physical && m.inHome === true && m.allocations && typeof m.allocations === "object") {
    for (const [roomId, n] of Object.entries(m.allocations as Record<string, unknown>)) {
      const q = int(n, 1, 9999);
      if (isId(roomId) && q) allocations[roomId] = q;
    }
  }
  const purpose = oneOf(m.purpose, PURPOSES, "home");
  const box = m.lineBox as Record<string, unknown> | null | undefined;
  const num = (v: unknown) => (typeof v === "number" && Number.isFinite(v) ? Math.min(Math.max(v, 0), 1) : 0);
  return {
    name: str(m.name, 200) ?? "Unnamed item",
    category: oneOf(m.category, CATEGORIES, "other"),
    type,
    purpose,
    carId: purpose === "car" && isId(m.carId) ? m.carId : null,
    inHome: physical && m.inHome === true,
    allocations,
    roomIds: Object.keys(allocations),
    quantity,
    unitPriceMinor: int(m.unitPriceMinor, -1e10, 1e10),
    lineTotalMinor: int(m.lineTotalMinor, -1e10, 1e10),
    serial: str(m.serial, 100),
    model: str(m.model, 100),
    notes: str(m.notes, 2000),
    highValue: m.highValue === true,
    lineBox: box && typeof box === "object"
      ? { page: int(box.page, 0, 100) ?? 0, x: num(box.x), y: num(box.y), w: num(box.w), h: num(box.h) }
      : null,
    extracted: m.extracted && typeof m.extracted === "object" ? m.extracted : {},
  };
}

/**
 * Writes one receipt and all its items in one transaction and assigns the
 * readable HV number. A repeated saveKey returns the first result, so
 * repeat taps and retries never duplicate.
 */
export async function saveReceiptFor(uid: string, data: SaveRequest): Promise<SaveResponse> {
  const saveKey = str(data.saveKey, 100);
  const receiptId = data.receiptId;
  if (!saveKey || !/^[A-Za-z0-9-]{8,100}$/.test(saveKey)) {
    throw new HttpsError("invalid-argument", "Missing save key.");
  }
  if (!isId(receiptId)) throw new HttpsError("invalid-argument", "Missing receipt id.");
  const r = data.receipt ?? {};
  const rawItems = Array.isArray(data.items) ? data.items : [];
  if (rawItems.length > MAX_ITEMS) {
    throw new HttpsError("invalid-argument", `A receipt can have up to ${MAX_ITEMS} items.`);
  }
  const items = rawItems.map(cleanItem);

  // One stored original per receipt, under this receipt's own folder.
  const prefix = `users/${uid}/receipts/${receiptId}/`;
  const originalPaths = (Array.isArray(r.originalPaths) ? r.originalPaths : [])
    .filter((p): p is string => typeof p === "string")
    .slice(0, 20);
  for (const p of originalPaths) {
    if (!p.startsWith(prefix) || !/original-\d+\.(jpg|pdf)$/.test(p)) {
      throw new HttpsError("invalid-argument", "Original is not in this receipt's folder.");
    }
  }
  const saveKeyRef = db.doc(`${userPath(uid)}/saveKeys/${saveKey}`);
  const already = await saveKeyRef.get();
  if (already.exists) return previous(uid, already.data()!);

  for (const p of originalPaths) {
    const [exists] = await bucket().file(p).exists();
    if (!exists) throw new HttpsError("failed-precondition", "The original has not finished uploading.");
  }

  const userRef = db.doc(userPath(uid));
  const receiptRef = db.doc(`${userPath(uid)}/receipts/${receiptId}`);
  const shop = str(r.shop, 120);
  const purchaseDate = isoDate(r.purchaseDate);
  const currency = oneOf(r.currency, CURRENCIES, "GBP");
  const orderNumber = str(r.orderNumber, 80);
  const originalTypes = (Array.isArray(r.originalTypes) ? r.originalTypes : [])
    .slice(0, originalPaths.length)
    .map((t) => (t === "application/pdf" ? "application/pdf" : "image/jpeg"));

  return db.runTransaction(async (tx) => {
    const [keySnap, receiptSnap, userSnap] = await Promise.all([
      tx.get(saveKeyRef), tx.get(receiptRef), tx.get(userRef),
    ]);
    if (keySnap.exists) return previous(uid, keySnap.data()!);
    if (receiptSnap.exists) {
      const d = receiptSnap.data()!;
      return { receiptId, number: d.number, itemIds: d.itemIds ?? [], alreadySaved: true };
    }
    const counter = ((userSnap.data()?.receiptCounter as number | undefined) ?? 0) + 1;
    const number = receiptNumber(counter);
    const itemIds = items.map((_, i) => `${receiptId}-${i}`);
    const preview = items.find((i) => i.type === "physical")?.name ?? items[0]?.name ?? null;

    tx.set(userRef, { receiptCounter: counter }, { merge: true });
    tx.set(receiptRef, {
      number,
      shop,
      purchaseDate,
      currency,
      totalMinor: int(r.totalMinor, -1e10, 1e10),
      taxMinor: int(r.taxMinor, -1e10, 1e10),
      orderNumber,
      source: oneOf(r.source, SOURCES, "manual"),
      originalPaths,
      originalTypes,
      checksum: str(r.checksum, 100),
      ocrText: str(r.ocrText, 20000),
      returnWording: str(r.returnWording, 500),
      extracted: r.extracted && typeof r.extracted === "object" ? r.extracted : {},
      status: "saved",
      saveKey,
      itemCount: items.length,
      itemIds,
      itemPreview: preview,
      searchTokens: receiptTokens(shop, number, orderNumber),
      confirmedAt: FieldValue.serverTimestamp(),
      revision: 1,
    });
    items.forEach((item, i) => {
      tx.set(db.doc(`${userPath(uid)}/items/${itemIds[i]}`), {
        ...item,
        receiptId,
        receiptNumber: number,
        purchaseDate,
        shop,
        currency,
        status: "owned",
        estimated: false,
        photoCount: 0,
        searchTokens: searchTokens([
          item.name, shop, CATEGORY_LABELS[item.category], number, item.serial, item.model,
        ]),
        createdAt: FieldValue.serverTimestamp(),
      });
    });
    tx.set(saveKeyRef, { receiptId, number, itemIds, createdAt: FieldValue.serverTimestamp() });
    return { receiptId, number, itemIds, alreadySaved: false };
  });
}

function previous(_uid: string, d: FirebaseFirestore.DocumentData): SaveResponse {
  return {
    receiptId: d.receiptId,
    number: d.number,
    itemIds: d.itemIds ?? [],
    alreadySaved: true,
  };
}

export const receiptTokens = (shop: string | null, number: string, orderNumber: string | null) =>
  searchTokens([shop, number, number.replace("-", ""), orderNumber]);

export const saveReceipt = onCall<SaveRequest>({ timeoutSeconds: 120 }, async (request) =>
  saveReceiptFor(requireUid(request), request.data ?? {}),
);

/** Deletes a receipt, its stored original and its items. */
export async function deleteReceiptFor(uid: string, receiptId: string) {
  const ref = db.doc(`${userPath(uid)}/receipts/${receiptId}`);
  const items = await db.collection(`${userPath(uid)}/items`).where("receiptId", "==", receiptId).get();
  for (const d of items.docs) await deleteItemData(uid, d.id, { skipReceipt: true });
  await bucket().deleteFiles({ prefix: `users/${uid}/receipts/${receiptId}/` }).catch(() => undefined);
  await db.doc(`${userPath(uid)}/returns/${receiptId}`).delete();
  await ref.delete();
}

export const deleteReceipt = onCall<{ receiptId?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const id = request.data?.receiptId;
  if (!isId(id)) throw new HttpsError("invalid-argument", "Missing receipt id.");
  await deleteReceiptFor(uid, id);
  return { ok: true };
});

/**
 * Keeps item copies of the shop and date in step with receipt edits,
 * refreshes search tokens, and recomputes spending totals.
 */
export const onReceiptWritten = onDocumentWritten(
  "users/{uid}/receipts/{receiptId}",
  async (event) => {
    const { uid, receiptId } = event.params;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (after) {
      const tokens = receiptTokens(after.shop ?? null, after.number ?? "", after.orderNumber ?? null);
      if (!sameArray(after.searchTokens, tokens)) {
        await event.data!.after.ref.update({ searchTokens: tokens });
      }
      if (before && (before.shop !== after.shop || before.purchaseDate !== after.purchaseDate ||
          before.currency !== after.currency)) {
        const items = await db.collection(`${userPath(uid)}/items`).where("receiptId", "==", receiptId).get();
        const batch = db.batch();
        for (const d of items.docs) {
          batch.update(d.ref, {
            shop: after.shop ?? null,
            purchaseDate: after.purchaseDate ?? null,
            currency: after.currency ?? "GBP",
          });
        }
        await batch.commit();
      }
    }
    const money = (d?: FirebaseFirestore.DocumentData) =>
      d ? `${d.totalMinor}|${d.currency}|${d.purchaseDate}|${d.itemCount}` : "";
    if (money(before) !== money(after)) await recomputeStats(uid);
  },
);
