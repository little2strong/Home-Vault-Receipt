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

  /// The Firebase plugins rewrite `localhost` and `127.0.0.1` to
  /// `10.0.2.2` on Android, which only works inside the Android emulator.
  /// Passing EMULATOR_HOST explicitly (e.g. `127.0.0.1` for a phone on
  /// `adb reverse`, or the PC's LAN address) turns that rewrite off.
  static const mapEmulatorHost = !bool.hasEnvironment('EMULATOR_HOST');

  /// Google OAuth web client id. Firebase accepts Google ID tokens issued
  /// for this client.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '918178599820-i4uqie1usg3rnrje5v7vtr9rbtu8hkko.apps.googleusercontent.com',
  );

  /// Google OAuth iOS client id; its reversed form is the URL scheme in
  /// `ios/Runner/Info.plist`.
  static const googleIosClientId =
      '918178599820-pf0itjhchuflnrsk8ht4pqc671p6r73j.apps.googleusercontent.com';

  /// UK region: Firestore, Storage and Functions all live here.
  static const functionsRegion = 'europe-west2';

  static const androidPackage = 'com.homevault.home_vault_receipt';
  static const iosBundleId = 'com.homevault.homeVaultReceipt';

  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
}
