import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/firebase_bootstrap.dart';

/// Reminders arriving while the app is closed are shown by the system;
/// nothing needs to run here, but FCM requires the handler on Android.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  runApp(const App());
}
