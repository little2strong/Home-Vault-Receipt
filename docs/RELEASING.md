# Android release checklist

The app uses package `com.homevault.home_vault_receipt`, display name
**Box of Receipts**, and version `1.0.0+1` in `pubspec.yaml`.
The installed Flutter 3.44.1 SDK supplies compile/target API 36. Verify these
values again if you change Flutter versions. Google Play requires API 36 or
higher for new phone apps and updates as of August 31, 2026.

## Configure signing once

If this app already has an upload keystore, use it. Otherwise create one
in PowerShell (the command prompts for passwords and certificate details):

```powershell
keytool -genkeypair -v -keystore "$env:USERPROFILE/home-vault-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
Copy-Item android/key.properties.example android/key.properties
```

Edit `android/key.properties` locally with the keystore's absolute path,
store password, alias and key password. Use forward slashes in the path,
for example `C:/Users/YourName/home-vault-upload.jks`. Java properties syntax
requires literal backslashes in passwords to be doubled.
The file and Android keystores are already ignored by Git. Keep a secure
backup of the upload key and its passwords outside the repository.

Release builds use only this signing configuration and fail if it is missing
or incomplete. Debug builds continue to use the normal debug key.

## Resolve before submission

- Replace `support@homevault.example` in
  `lib/features/account/view/account_pages.dart` with a monitored address.
- Replace the template Flutter launcher icons under
  `android/app/src/main/res/mipmap-*` with the final Box of Receipts icon.
- Host a public privacy policy and an account deletion request page. The app
  has in-app policy and deletion screens, but Google Play also requires an
  external deletion request URL for apps that allow account creation. Verify
  that policy claims, including data location and backup retention, match
  the deployed services.
- Verify the Firebase setup checklist in `README.md`: production billing,
  deployed Functions, Storage and Firestore rules/indexes, enabled sign-in
  providers, export permissions, and App Check registration. Repository
  configuration alone does not confirm live deployment status.
- Add the upload certificate SHA-1 and SHA-256 to the Firebase Android app.
  After enabling Play App Signing, also register the **Play app signing**
  certificate fingerprints from Play Console. Download the updated
  `google-services.json` into `android/app/` and rebuild if its OAuth
  configuration changes. Google sign-in and Play Integrity must work in
  the build installed from Play, with its Play signing certificate.

To display the upload certificate fingerprints (password is prompted):

```powershell
keytool -list -v -keystore "$env:USERPROFILE/home-vault-upload.jks" -alias upload
```

## Validate and build

From the repository root:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Do not enable `USE_EMULATORS` for a store build. The bundle is written to
`build/app/outputs/bundle/release/app-release.aab`.
For subsequent submissions, increase the build number after `+` in
`pubspec.yaml`, or pass a new `--build-number` to the build command.

Upload the signed bundle to Play Console's internal testing track first.
Enable Play App Signing and test Google/email sign-in, receipt capture and
OCR, uploads, reminders, exports, account deletion, and offline retry on a
physical device. Check the pre-launch report and native library 16 KB page
size compatibility; a successful local build does not establish these.

Complete the store listing (icon, screenshots, descriptions and contact
details), privacy policy URL, account deletion URL, Data safety form,
content rating, ads/target audience declarations, and reviewer app access
instructions. Base Data safety answers on the actual app and included SDKs,
including Firebase Auth, Storage, Crashlytics and Messaging. Complete any
closed testing requirement shown for your developer account before applying
for production access.

## References

- [Flutter Android release guide](https://docs.flutter.dev/deployment/android)
- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111)
