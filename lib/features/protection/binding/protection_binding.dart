import 'package:get/get.dart';

import '../controller/protection_controller.dart';

class ProtectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProtectionController(ownership: Get.find()));
  }
}
