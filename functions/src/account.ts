import * as functionsV1 from "firebase-functions/v1";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { FieldValue, REGION, auth, bucket, db, requireUid, userPath } from "./common";

/** On first sign-in a Function creates `users/{uid}`. */
export async function createProfile(uid: string, email?: string | null, displayName?: string | null) {
  const ref = db.doc(userPath(uid));
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data() ?? {};
    tx.set(ref, {
      ...(snap.exists ? {} : {
        displayName: displayName ?? null,
        email: email ?? null,
        timezone: "Europe/London",
        locale: "en_GB",
        mainCurrency: "GBP",
        reminderMinutes: 9 * 60,
        warrantyReminders: true,
        returnReminders: true,
        keepPhotoLocation: false,
        createdAt: FieldValue.serverTimestamp(),
      }),
      receiptCounter: typeof d.receiptCounter === "number" ? d.receiptCounter : 0,
      status: d.status ?? "active",
    }, { merge: true });
  });
}

export const onUserCreated = functionsV1.region(REGION).auth.user().onCreate(async (user) => {
  await createProfile(user.uid, user.email, user.displayName);
});

/** Removes Firestore data, Storage files, exports and the sign-in itself. */
export async function deleteAccountData(uid: string) {
  await db.recursiveDelete(db.doc(userPath(uid)));
  await bucket().deleteFiles({ prefix: `users/${uid}/` }).catch(() => undefined);
  await auth.deleteUser(uid).catch((e: { code?: string }) => {
    if (e.code !== "auth/user-not-found") throw e;
  });
}

/** Requires a sign-in within the last 5 minutes. */
export const deleteAccount = onCall({ timeoutSeconds: 540, memory: "512MiB" }, async (request) => {
  const uid = requireUid(request);
  const authTime = request.auth?.token.auth_time as number | undefined;
  if (!authTime || Date.now() / 1000 - authTime > 5 * 60) {
    throw new HttpsError("failed-precondition", "Please sign in again to confirm, then delete within 5 minutes.");
  }
  await deleteAccountData(uid);
  return { ok: true };
});
