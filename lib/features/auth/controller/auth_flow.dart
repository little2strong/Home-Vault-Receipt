import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/user_account.dart';
import '../../../core/repositories/settings_repository.dart';

/// Where a freshly signed-in user lands, shared by every auth screen.
abstract final class AuthFlow {
  static Future<void> enterApp(UserAccount user) async {
    final settings = Get.find<SettingsRepository>();
    await settings.registerCurrentDevice(_deviceName());
    if (kDebugMode) await settings.seedSampleDevices();
    Get.offAllNamed(user.emailVerified ? Routes.shell : Routes.verifyEmail);
  }

  static String _deviceName() => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'This iPhone',
    TargetPlatform.android => 'This Android phone',
    TargetPlatform.macOS => 'This Mac',
    TargetPlatform.windows => 'This Windows PC',
    TargetPlatform.linux => 'This Linux PC',
    TargetPlatform.fuchsia => 'This device',
  };
}
