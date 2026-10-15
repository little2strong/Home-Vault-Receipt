import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'app_config.dart';

/// Starts Firebase once, before the first frame.
abstract final class FirebaseBootstrap {
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Offline cache is built in; drafts and lists keep working offline.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (AppConfig.useEmulators) {
      const host = AppConfig.emulatorHost;
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      functions.useFunctionsEmulator(host, 5001);
    }

    await _appCheck();
    _crashReporting();
    unawaited(_remoteConfig());
  }

  /// Monitoring first; enforcement is switched on in the console later.
  static Future<void> _appCheck() async {
    if (AppConfig.useEmulators) return;
    try {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleAppAttestWithDeviceCheckFallbackProvider(),
      );
    } catch (e) {
      debugPrint('App Check not active: ${e.runtimeType}');
    }
  }

  /// Crash reports carry stack traces only — never receipt text, images,
  /// addresses or tokens.
  static void _crashReporting() {
    final crashlytics = FirebaseCrashlytics.instance;
    unawaited(crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode));
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(
        error.runtimeType.toString(),
        stack,
        fatal: true,
        reason: 'uncaught',
      );
      return true;
    };
  }

  static Future<void> _remoteConfig() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(Limits.defaults);
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 6),
        ),
      );
      await rc.fetchAndActivate();
    } catch (_) {
      // Defaults stay in force offline.
    }
  }
}

/// Limits that can change without an app update.
abstract final class Limits {
  static const defaults = <String, Object>{
    'photos_per_item': 10,
    'room_video_seconds': 120,
    'pdf_max_pages': 20,
    'receipt_pages': 10,
  };

  static int _int(String key) {
    try {
      final v = FirebaseRemoteConfig.instance.getInt(key);
      if (v > 0) return v;
    } catch (_) {}
    return defaults[key]! as int;
  }

  static int get photosPerItem => _int('photos_per_item');
  static int get roomVideoSeconds => _int('room_video_seconds');
  static int get pdfMaxPages => _int('pdf_max_pages');
  static int get receiptPages => _int('receipt_pages');
}
