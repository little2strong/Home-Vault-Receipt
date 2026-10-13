import 'package:get/get.dart';

import '../controller/moving_controller.dart';

class MovingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MovingController(ownership: Get.find()));
  }
}
