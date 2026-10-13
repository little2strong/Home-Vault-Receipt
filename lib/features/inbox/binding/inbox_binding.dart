import 'package:get/get.dart';

import '../controller/inbox_controller.dart';

class InboxBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InboxController(ownership: Get.find()));
  }
}
