import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

enum ShellTab { home, receipts, more }

class ShellController extends GetxController {
  final current = ShellTab.home.obs;

  void select(ShellTab tab) => current.value = tab;

  /// Pops back to the tabs from anywhere and shows [tab].
  static void openTab(ShellTab tab) {
    Get.until((route) => route.settings.name == Routes.shell);
    if (Get.isRegistered<ShellController>()) {
      Get.find<ShellController>().select(tab);
    }
  }
}
