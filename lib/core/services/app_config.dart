import 'package:flutter/foundation.dart';

/// Build-time settings, passed with `--dart-define`.
///
/// ```
/// flutter run --dart-define=USE_EMULATORS=true
/// ```
abstract final class AppConfig {
  /// Firestore, Storage, Functions and rules run on the Local Emulator Suite.
  static const useEmulators = bool.fromEnvironment('USE_EMULATORS');

  /// Host of the emulators; `10.0.2.2` reaches the PC from the Android
  /// emulator.
  static const emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// Google OAuth web client id, needed by Google sign-in on Android.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// UK region: Firestore, Storage and Functions all live here.
  static const functionsRegion = 'europe-west2';

  static const androidPackage = 'com.homevault.home_vault_receipt';
  static const iosBundleId = 'com.homevault.homeVaultReceipt';

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
}
