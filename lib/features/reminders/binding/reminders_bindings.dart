import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/reminder_detail_controller.dart';
import '../controller/reminders_controller.dart';

class RemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => RemindersController(receipts: Get.find(), settings: Get.find()),
    );
  }
}

class ReminderDetailBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => ReminderDetailController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}
