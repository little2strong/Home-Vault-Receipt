import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

import '../data/vault_repository.dart';
import '../data/vault_store.dart';

/// Warranty and return reminders arrive by FCM from a scheduled Function,
/// in the user's own timezone. Permission is asked when the first reminder
/// is set, after the explainer page — never at sign-up.
class NotificationService extends GetxService {
  NotificationService(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;

  final permission = AuthorizationStatus.notDetermined.obs;
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSub;
  Worker? _userWorker;

  /// A route to open when the app was launched from a reminder.
  String? pendingRoute;

  static const _channel = AndroidNotificationChannel(
    'reminders',
    'Reminders',
    description: 'Warranty and return reminders you have confirmed.',
    importance: Importance.high,
  );

  bool get granted =>
      permission.value == AuthorizationStatus.authorized ||
      permission.value == AuthorizationStatus.provisional;

  @override
  void onInit() {
    super.onInit();
    if (kIsWeb) return;
    unawaited(_setUp());
    _userWorker = ever(store.user, (u) {
      if (u != null) unawaited(syncDevice());
    });
  }

  Future<void> _setUp() async {
    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _open(r.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      permission.value = settings.authorizationStatus;

      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => _open(m.data['route'] as String?),
      );
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      pendingRoute = initial?.data['route'] as String?;
    } catch (e) {
      debugPrint('Notifications unavailable: ${e.runtimeType}');
    }
  }

  /// Shows the system prompt. Returns true when reminders can be sent.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final settings = await FirebaseMessaging.instance.requestPermission();
    permission.value = settings.authorizationStatus;
    if (store.uid != null) {
      await repo.updateProfile({'notificationsAsked': true});
    }
    if (granted) await syncDevice();
    return granted;
  }

  /// Registers this device's token and timezone so reminders reach it at
  /// the right local time.
  Future<void> syncDevice() async {
    if (kIsWeb || store.uid == null) return;
    try {
      final tz = await currentTimezone();
      await repo.ensureProfile(
        displayName: store.user.value?.displayName,
        email: store.user.value?.email,
        timezone: tz,
      );
      if (!granted) return;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns == null) return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await repo.registerDevice(token, defaultTargetPlatform.name, tz);
      }
      await _tokenSub?.cancel();
      _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (t) => repo.registerDevice(t, defaultTargetPlatform.name, tz),
      );
    } catch (e) {
      debugPrint('Device not registered: ${e.runtimeType}');
    }
  }

  static Future<String> currentTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return info.identifier;
    } catch (_) {
      return 'Europe/London';
    }
  }

  Future<void> _showForeground(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await _local.show(
      id: m.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: m.data['route'] as String?,
    );
  }

  void _open(String? route) {
    if (route == null || route.isEmpty) return;
    Get.toNamed(route);
  }

  @override
  void onClose() {
    _tokenSub?.cancel();
    _userWorker?.dispose();
    super.onClose();
  }
}
