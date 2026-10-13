import 'package:get/get.dart';

import '../../dashboard/controller/dashboard_controller.dart';
import '../../receipts/controller/receipts_controller.dart';
import '../../settings/controller/settings_controller.dart';
import '../controller/shell_controller.dart';

/// The three tabs live as long as the shell route.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    Get.lazyPut(
      () => DashboardController(receipts: Get.find(), auth: Get.find()),
    );
    Get.lazyPut(() => ReceiptsController(receipts: Get.find()));
    Get.lazyPut(
      () => SettingsController(
        auth: Get.find(),
        receipts: Get.find(),
        settings: Get.find(),
      ),
    );
  }
}
