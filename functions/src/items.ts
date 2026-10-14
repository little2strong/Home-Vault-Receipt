import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  CATEGORY_LABELS, FieldValue, bucket, db, isId, requireUid, sameArray, searchTokens, userPath,
} from "./common";
import { recomputeStats } from "./stats";

/** Removes an item, its photos, warranty and card photo. */
export async function deleteItemData(uid: string, itemId: string, opts: { skipReceipt?: boolean } = {}) {
  const ref = db.doc(`${userPath(uid)}/items/${itemId}`);
  const snap = await ref.get();
  await db.recursiveDelete(ref.collection("photos"));
  await bucket().deleteFiles({ prefix: `users/${uid}/items/${itemId}/` }).catch(() => undefined);
  await db.doc(`${userPath(uid)}/warranties/${itemId}`).delete();
  await ref.delete();
  const receiptId = snap.data()?.receiptId as string | undefined;
  if (receiptId && !opts.skipReceipt) {
    const receiptRef = db.doc(`${userPath(uid)}/receipts/${receiptId}`);
    await db.runTransaction(async (tx) => {
      const r = await tx.get(receiptRef);
      if (!r.exists) return;
      const ids = ((r.data()!.itemIds as string[] | undefined) ?? []).filter((i) => i !== itemId);
      tx.update(receiptRef, { itemCount: FieldValue.increment(-1), itemIds: ids });
    });
  }
}

export const deleteItem = onCall<{ itemId?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const id = request.data?.itemId;
  if (!isId(id)) throw new HttpsError("invalid-argument", "Missing item id.");
  await deleteItemData(uid, id);
  return { ok: true };
});

/** Photo count and cover thumbnail, kept on the item for lists. */
export async function refreshPhotoSummary(uid: string, itemId: string) {
  const itemRef = db.doc(`${userPath(uid)}/items/${itemId}`);
  const photos = await itemRef.collection("photos").orderBy("createdAt").get();
  const cover = photos.docs.find((d) => d.data().thumbPath)?.data().thumbPath ?? null;
  const item = await itemRef.get();
  if (!item.exists) return;
  await itemRef.update({ photoCount: photos.size, coverThumbPath: cover });
}

export const deletePhoto = onCall<{ itemId?: unknown; photoId?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const { itemId, photoId } = request.data ?? {};
  if (!isId(itemId) || !isId(photoId)) throw new HttpsError("invalid-argument", "Missing photo.");
  const base = `users/${uid}/items/${itemId}/photos`;
  await Promise.all([
    bucket().file(`${base}/${photoId}.jpg`).delete({ ignoreNotFound: true }),
    bucket().file(`${base}/thumbs/${photoId}.jpg`).delete({ ignoreNotFound: true }),
  ]);
  await db.doc(`${userPath(uid)}/items/${itemId}/photos/${photoId}`).delete();
  await refreshPhotoSummary(uid, itemId);
  return { ok: true };
});

/** Items in the room lose that room; they stay in the vault. */
export const deleteRoom = onCall<{ roomId?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const roomId = request.data?.roomId;
  if (!isId(roomId)) throw new HttpsError("invalid-argument", "Missing room id.");
  const items = await db.collection(`${userPath(uid)}/items`).where("roomIds", "array-contains", roomId).get();
  const batch = db.batch();
  for (const d of items.docs) {
    batch.update(d.ref, {
      [`allocations.${roomId}`]: FieldValue.delete(),
      roomIds: FieldValue.arrayRemove(roomId),
    });
  }
  batch.delete(db.doc(`${userPath(uid)}/rooms/${roomId}`));
  await batch.commit();
  await bucket().deleteFiles({ prefix: `users/${uid}/rooms/${roomId}/` }).catch(() => undefined);
  return { ok: true, itemsMoved: items.size };
});

export const deleteRoomVideo = onCall<{ roomId?: unknown }>(async (request) => {
  const uid = requireUid(request);
  const roomId = request.data?.roomId;
  if (!isId(roomId)) throw new HttpsError("invalid-argument", "Missing room id.");
  await bucket().file(`users/${uid}/rooms/${roomId}/walkthrough.mp4`).delete({ ignoreNotFound: true });
  await db.doc(`${userPath(uid)}/rooms/${roomId}`).update({
    videoPath: null, videoUploadedAt: null, videoSeconds: null,
  });
  return { ok: true };
});

const STAT_FIELDS = [
  "category", "purpose", "carId", "lineTotalMinor", "purchaseDate", "currency", "receiptId",
];

/**
 * Keeps search tokens current (name, shop, category, room, receipt number)
 * and recomputes spending when an item's money or tags change.
 */
export const onItemWritten = onDocumentWritten("users/{uid}/items/{itemId}", async (event) => {
  const { uid, itemId } = event.params;
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (after) {
    const roomIds: string[] = Array.isArray(after.roomIds) ? after.roomIds : Object.keys(after.allocations ?? {});
    const rooms = await Promise.all(
      roomIds.map((id) => db.doc(`${userPath(uid)}/rooms/${id}`).get()),
    );
    const tokens = searchTokens([
      after.name, after.shop, CATEGORY_LABELS[after.category] ?? after.category,
      after.receiptNumber, after.serial, after.model,
      ...rooms.map((r) => r.data()?.name as string | undefined),
    ]);
    const patch: Record<string, unknown> = {};
    if (!sameArray(after.searchTokens, tokens)) patch.searchTokens = tokens;
    if (!sameArray(after.roomIds, roomIds)) patch.roomIds = roomIds;
    if (Object.keys(patch).length) await event.data!.after.ref.update(patch);
    if (before && before.name !== after.name) {
      const w = db.doc(`${userPath(uid)}/warranties/${itemId}`);
      if ((await w.get()).exists) await w.update({ itemName: after.name });
    }
  }
  // Items created by saveReceipt are counted by the receipt trigger.
  const createdWithReceipt = !before && after?.receiptId;
  const changed = STAT_FIELDS.some((f) => before?.[f] !== after?.[f]);
  if (changed && !createdWithReceipt && (before?.receiptId || after?.receiptId)) {
    await recomputeStats(uid);
  }
});
