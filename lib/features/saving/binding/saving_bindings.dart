import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/pending_controller.dart';
import '../controller/save_result_controller.dart';
import '../controller/saving_controller.dart';

class SavingBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => SavingController(
        receipts: Get.find(),
        saver: Get.find(),
        receiptId: id,
      ),
      tag: currentRouteTag,
    );
  }
}

class SaveResultBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => SaveResultController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}

class PendingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PendingController(
        receipts: Get.find(),
        saver: Get.find(),
        uploads: Get.find(),
      ),
    );
  }
}
