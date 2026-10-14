import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Real paths (/products, /finish-sign-in) so email links and bookmarks
  // work on the website.
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.init();

  String? initialLink;
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    try {
      final uri = await AppLinks().getInitialLink();
      final link = uri?.toString();
      if (link != null && FirebaseAuth.instance.isSignInWithEmailLink(link)) {
        initialLink = link;
      }
    } catch (_) {}
  }
  runApp(App(initialLink: initialLink));
}
