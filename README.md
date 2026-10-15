# Home Vault

Receipts and a room-by-room home inventory: a Flutter app for Android and
iOS only, running entirely on Firebase. Built to the
*Home Vault — Developer Spec (Flutter + Firebase)* of 6 October 2026.

## Product rules that never bend

1. Nothing is saved until the user checks it. Unknown values stay "Not stated".
2. One receipt means one record and one stored original, however many items.
3. Originals and photos are private and load only when the user asks.
4. Viewing, exporting and deleting data are always free.
5. The app never says an item is verified, protected or insured.

## Stack

Flutter with GetX (state, routing, dependency injection) · Firebase Auth
(Google, email and password) · Cloud Firestore · Cloud Storage · Cloud
Functions (TypeScript, 2nd gen) · Cloud Messaging · App Check · Crashlytics ·
Remote Config · on-device ML Kit text recognition and document scanner.

## Getting started

```bash
flutter pub get
flutter run                                          # app against the live project
flutter run --dart-define=USE_EMULATORS=true         # app against local emulators
```

Running against the emulators from an Android emulator also needs
`--dart-define=EMULATOR_HOST=10.0.2.2`.

Firebase CLI emulators need **Java 21 or newer** (`java -version`).

The Cloud Functions live in `functions/`:

```bash
cd functions
npm install
npm run build
```

## Folder structure

```
lib/
├── main.dart                  Firebase start-up, then the app
├── firebase_options.dart      FlutterFire config (Android, iOS)
├── app/                       GetMaterialApp, routes, app-wide bindings
├── core/
│   ├── constants/             Design tokens (colours, spacing, radii)
│   ├── data/                  AuthRepository, VaultStore (live Firestore
│   │                          streams), VaultRepository (writes and
│   │                          callable Functions), FileStore (Storage)
│   ├── models/                Receipt, Item, Room, Warranty, drafts…
│   ├── parsing/               OCR document model and the UK receipt parser
│   ├── services/              Capture, ML Kit text recognition, image tools
│   │                          (resize, strip GPS, SHA-256), draft store,
│   │                          ReceiptSaver (idempotent saves, offline retry),
│   │                          notifications, connectivity
│   ├── theme/, utils/, widgets/
└── features/                  One folder per area, GetX style
    ├── start/                 01–05 splash, welcome, sign-in, create account,
    │                          forgot password, reminders
    ├── shell/                 tab bar with the centre Add button
    ├── home/                  06 Home, 07 Search
    ├── add/                   08–18 add sheet, camera, pages, reading, review,
    │                          edit item, duplicate, saved, manual, own item
    ├── products/              19–25 products, filters, item, receipt,
    │                          original viewer, photos, photo tips
    ├── rooms/                 26–29 home setup, rooms, room, walkthrough video
    ├── warranties/            30–31 warranties, edit warranty
    ├── account/               32–38 account, spending, cars, export, export
    │                          ready, settings, delete; plus pending, help, legal
functions/src/                 Cloud Functions and their tests
firestore.rules, storage.rules, firestore.indexes.json, firebase.json
```

Features follow the GetX layout: a controller (a `GetxController` holding
reactive state) and a view (`GetView`), registered by a binding in
`app/routes/app_pages.dart`.

## How saving works

1. Pages are captured (ML Kit document scanner on Android, the in-app camera
   on iOS, photos or a PDF) and copied into the app's own folder.
2. ML Kit reads the text on the phone. `ReceiptParser` proposes the shop,
   date, total, VAT, items and any return wording.
3. The user checks step 1 (details) and step 2 (items, with Type, Purpose and
   Room). The draft is stored on the phone after every change.
4. Originals upload to `users/{uid}/receipts/{receiptId}/original-{n}`, then
   the `saveReceipt` Function writes the receipt and all its items in one
   transaction and assigns the HV number. A client-made `saveKey` makes
   repeat taps and retries harmless.
5. "Saved" is shown only after the server confirms. Offline, the draft waits
   and saves itself when the connection returns.

## Cloud Functions

| Function | What it does |
| --- | --- |
| `saveReceipt` | Idempotent save, HV number, receipt and items in one transaction |
| `deleteReceipt`, `deleteItem`, `deletePhoto`, `deleteRoom`, `deleteRoomVideo` | Deletes go through Functions so files and records go together |
| `deleteAccount` | Requires a sign-in within 5 minutes; removes Firestore data, files, exports and the Auth user |
| `onUserCreated` | Creates `users/{uid}` on first sign-in |
| `onReceiptWritten`, `onItemWritten` | Search tokens, item copies of shop and date, spending stats |
| `dailyStats` | Moves the 30-day and 1-year windows each night |
| `onFileUploaded` | Photo evidence: server upload time, SHA-256, 400 px thumbnail; room video upload time |
| `onWarrantyWritten`, `onReturnWritten`, `onProfileWritten` | Schedule reminders in the user's own timezone |
| `sendReminders` | Every 15 minutes, sends due reminders by FCM |
| `onExportRequested`, `cleanupExports` | PDF, CSV and ZIP exports; 24-hour links; expired files deleted |

## Tests

```bash
flutter analyze
flutter test                       # parser, models, filters, 20 screen tests

cd functions
npm run build
firebase emulators:exec --only firestore,storage,auth --project demo-homevault \
  "npx mocha --timeout 30000 lib/test/**/*.test.js"
```

The Functions tests run against the Emulator Suite. They cover idempotent
saves, receipt numbering, stats per currency, reminders across the clock
change, exports, account deletion, and the security rules (a second user
cannot read or write the first user's data, and clients cannot write
receipt numbers, totals, upload times or export links). The emulators need
**Java 21 or newer**.

## Firebase setup checklist

The project is `home-vault-receipt-b47a5` (see `.firebaserc`).

Done from this repo:
- Android and iOS apps are registered in `lib/firebase_options.dart`.
- The debug SHA-1 and SHA-256 are added to the Android app.
- Firestore is in `europe-west2`, with rules and indexes deployed.

Still to do in the Firebase / Google Cloud console:
1. **Upgrade to the Blaze plan** and set budget alerts. Cloud Storage and
   Cloud Functions require it. Then run `firebase deploy --only storage,functions`.
2. **Authentication › Sign-in method**: Google and Email/Password are on.
   The Google client IDs live in `android/app/google-services.json`,
   `lib/core/services/app_config.dart` and the URL scheme in
   `ios/Runner/Info.plist`. Every new signing key (release keystore, Play
   App Signing) needs its SHA-1 added to the Android app, then a fresh
   `google-services.json`.
3. **Apple**: enable Push for the bundle ID and upload an APNs key to
   Firebase Cloud Messaging.
4. **Storage**: if the default bucket is not in `europe-west2`, set
   `STORAGE_TRIGGER_REGION` (in `functions/.env`) to the bucket's region.
5. **App Check**: register Play Integrity and App Attest. Keep it in
   monitoring until traffic looks right, then enforce it.
6. **Signed export links**: grant the Functions service account
   *Service Account Token Creator* so exports use signed URLs. Without it,
   they fall back to a token link and the file is deleted after 24 hours.
7. Add the release keystore's SHA-256 to the Android app before publishing.

## Privacy

Text recognition runs on the phone. Photos lose their GPS location before
upload unless the user turns on "Keep photo location", and always in
exports. Crash reports carry no receipt text, images or tokens. Data is
encrypted in transit and at rest by Google; it is not end-to-end encrypted.
