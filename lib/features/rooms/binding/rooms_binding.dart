import 'package:get/get.dart';

import '../controller/rooms_controller.dart';

class RoomsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RoomsController(ownership: Get.find()));
  }
}
