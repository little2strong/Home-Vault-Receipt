import 'package:get/get.dart';

import '../controller/account_security_controller.dart';
import '../controller/delete_account_controller.dart';
import '../controller/export_controller.dart';
import '../controller/help_controller.dart';
import '../controller/notification_settings_controller.dart';

class NotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationSettingsController(settings: Get.find()));
  }
}

/// Security and devices share one controller.
class AccountSecurityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AccountSecurityController(auth: Get.find(), settings: Get.find()),
    );
  }
}

/// Selection and ready screens share one controller.
class ExportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ExportController(receipts: Get.find(), exporter: Get.find()),
    );
  }
}

class DeleteAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => DeleteAccountController(
        auth: Get.find(),
        receipts: Get.find(),
        settings: Get.find(),
      ),
    );
  }
}

class HelpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HelpController(uploads: Get.find()));
  }
}
