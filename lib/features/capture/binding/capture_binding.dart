import 'package:get/get.dart';

import '../controller/capture_controller.dart';

/// Shared by every capture step. The controller is created on Add source
/// and lives until that route leaves the stack.
class CaptureBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CaptureController(
        documents: Get.find(),
        receipts: Get.find(),
        settings: Get.find(),
      ),
    );
  }
}
