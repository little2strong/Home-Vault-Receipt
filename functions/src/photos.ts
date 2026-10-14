import { createHash } from "node:crypto";

import sharp from "sharp";
import { onObjectFinalized } from "firebase-functions/v2/storage";
import { defineString } from "firebase-functions/params";

import { FieldValue, bucket, db, userPath } from "./common";
import { refreshPhotoSummary } from "./items";

/** Storage triggers must run in the bucket's region. */
const storageRegion = defineString("STORAGE_TRIGGER_REGION", { default: "europe-west2" });

const PHOTO = /^users\/([^/]+)\/items\/([^/]+)\/photos\/([^/]+)\.jpg$/;
const VIDEO = /^users\/([^/]+)\/rooms\/([^/]+)\/walkthrough\.mp4$/;

/** 400 px thumbnails for lists; metadata (including GPS) is not copied. */
export async function makeThumbnail(jpeg: Buffer): Promise<Buffer> {
  return sharp(jpeg).rotate().resize(400, 400, { fit: "inside", withoutEnlargement: true })
    .jpeg({ quality: 78 }).toBuffer();
}

/**
 * Evidence record: when a photo reaches the server, its server-side
 * fingerprint and a thumbnail. Written only here, never by the app.
 */
export const onFileUploaded = onObjectFinalized(
  { region: storageRegion, memory: "1GiB" },
  async (event) => {
    const name = event.data.name ?? "";
    const photo = PHOTO.exec(name);
    if (photo) {
      const [, uid, itemId, photoId] = photo;
      const file = bucket().file(name);
      const [bytes] = await file.download();
      const sha256 = createHash("sha256").update(bytes).digest("hex");
      const thumbPath = `users/${uid}/items/${itemId}/photos/thumbs/${photoId}.jpg`;
      await bucket().file(thumbPath).save(await makeThumbnail(bytes), {
        contentType: "image/jpeg",
        resumable: false,
      });
      const ref = db.doc(`${userPath(uid)}/items/${itemId}/photos/${photoId}`);
      const snap = await ref.get();
      if (!snap.exists) {
        // Uploaded without a record: not evidence, remove it.
        await Promise.all([file.delete(), bucket().file(thumbPath).delete()]).catch(() => undefined);
        return;
      }
      await ref.update({
        serverUploadedAt: FieldValue.serverTimestamp(),
        thumbPath,
        serverSha256: sha256,
        fingerprintMatches: snap.data()?.sha256 === sha256,
        sizeBytes: bytes.length,
      });
      await refreshPhotoSummary(uid, itemId);
      return;
    }
    const video = VIDEO.exec(name);
    if (video) {
      const [, uid, roomId] = video;
      const ref = db.doc(`${userPath(uid)}/rooms/${roomId}`);
      if ((await ref.get()).exists) {
        await ref.update({ videoPath: name, videoUploadedAt: FieldValue.serverTimestamp() });
      }
    }
  },
);
