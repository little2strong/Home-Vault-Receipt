// Points the Admin SDK at the emulators started by `firebase emulators:exec`.
export const PROJECT = process.env.GCLOUD_PROJECT ?? "demo-homevault";
export const BUCKET = `${PROJECT}.appspot.com`;

process.env.GCLOUD_PROJECT = PROJECT;
process.env.FIREBASE_CONFIG = JSON.stringify({ projectId: PROJECT, storageBucket: BUCKET });
process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";
process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= "127.0.0.1:9199";
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "127.0.0.1:9099";

export async function clearFirestore() {
  await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`,
    { method: "DELETE" },
  );
}
