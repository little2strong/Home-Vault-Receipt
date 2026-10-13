import 'package:get/get.dart';

import '../controller/assistant_controller.dart';

class AssistantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AssistantController(receipts: Get.find(), ownership: Get.find()),
    );
  }
}
