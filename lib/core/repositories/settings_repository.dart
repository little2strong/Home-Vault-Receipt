import 'dart:convert';

import 'package:get/get.dart';

import '../models/notification_preferences.dart';
import '../models/user_account.dart';
import '../services/key_value_store.dart';
import '../utils/dates.dart';

/// Device-level preferences and signed-in sessions.
class SettingsRepository {
  SettingsRepository({required this._store, this._clock = DateTime.now}) {
    _load();
  }

  static const _key = 'settings.v1';

  final KeyValueStore _store;
  final Clock _clock;

  final onboardingSeen = false.obs;
  final cameraAllowed = false.obs;
  final appLock = false.obs;
  final notifications = const NotificationPreferences().obs;
  final devices = <DeviceSession>[].obs;

  Future<void> completeOnboarding() =>
      _update(() => onboardingSeen.value = true);

  Future<void> allowCamera() => _update(() => cameraAllowed.value = true);

  Future<void> setAppLock(bool enabled) =>
      _update(() => appLock.value = enabled);

  Future<void> saveNotifications(NotificationPreferences prefs) =>
      _update(() => notifications.value = prefs);

  /// Registers this device as the current session on sign-in.
  Future<void> registerCurrentDevice(String name) => _update(() {
    devices.removeWhere((d) => d.isCurrent);
    devices.insert(
      0,
      DeviceSession(
        id: 'current',
        name: name,
        location: 'This device',
        lastActive: _clock(),
        isCurrent: true,
      ),
    );
  });

  Future<void> revokeDevice(String id) =>
      _update(() => devices.removeWhere((d) => d.id == id && !d.isCurrent));

  Future<void> revokeOtherDevices() =>
      _update(() => devices.removeWhere((d) => !d.isCurrent));

  /// Called on sign-out and account deletion.
  Future<void> clearSessions() => _update(devices.clear);

  /// Adds a sample second session in debug builds so the device list has
  /// something to revoke.
  Future<void> seedSampleDevices() async {
    if (devices.any((d) => !d.isCurrent)) return;
    await _update(
      () => devices.add(
        DeviceSession(
          id: 'sample-mac',
          name: 'Mac browser',
          lastActive: _clock().subtract(const Duration(days: 10)),
        ),
      ),
    );
  }

  Future<void> _update(void Function() change) {
    change();
    return _store.write(
      _key,
      jsonEncode({
        'onboarding_seen': onboardingSeen.value,
        'camera_allowed': cameraAllowed.value,
        'app_lock': appLock.value,
        'notifications': notifications.value.toJson(),
        'devices': [for (final d in devices) d.toJson()],
      }),
    );
  }

  void _load() {
    final raw = _store.read(_key);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      onboardingSeen.value = json['onboarding_seen'] as bool? ?? false;
      cameraAllowed.value = json['camera_allowed'] as bool? ?? false;
      appLock.value = json['app_lock'] as bool? ?? false;
      notifications.value = NotificationPreferences.fromJson(
        json['notifications'] as Map<String, dynamic>? ?? const {},
      );
      devices.assignAll([
        for (final d in json['devices'] as List? ?? const [])
          DeviceSession.fromJson(d as Map<String, dynamic>),
      ]);
    } on Object {
      // Fall back to defaults on a corrupt store.
    }
  }
}
