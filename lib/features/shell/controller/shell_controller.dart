import 'package:get/get.dart';

import '../../../core/services/notification_service.dart';

class ShellController extends GetxController {
  final tab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) tab.value = args;
  }

  @override
  void onReady() {
    super.onReady();
    // Launched by tapping a reminder.
    if (Get.isRegistered<NotificationService>()) {
      final n = Get.find<NotificationService>();
      final route = n.pendingRoute;
      n.pendingRoute = null;
      if (route != null) Get.toNamed(route);
    }
  }
}
