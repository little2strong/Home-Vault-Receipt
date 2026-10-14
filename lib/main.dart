import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/app.dart';
import 'core/services/firebase_bootstrap.dart';

/// Reminders arriving while the app is closed are shown by the system;
/// nothing needs to run here, but FCM requires the handler on Android.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

Future<void> main() async {
  // Real paths (/products, /dashboard) so bookmarks work on the website.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  }
  runApp(const App());
}
