import 'package:get/get.dart';

import '../../../core/models/notification_preferences.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/utils/toast.dart';

/// 44 · Notification settings. Edits a copy; nothing changes until saved.
class NotificationSettingsController extends GetxController {
  NotificationSettingsController({required this._settings})
    : prefs = _settings.notifications.value.obs;

  final SettingsRepository _settings;
  final Rx<NotificationPreferences> prefs;

  bool get hasChanges => prefs.value != _settings.notifications.value;

  void change(NotificationPreferences Function(NotificationPreferences) edit) =>
      prefs.value = edit(prefs.value);

  Future<void> save() async {
    await _settings.saveNotifications(prefs.value);
    Get.back();
    Toast.show('Preferences saved');
  }
}
