import 'package:get/get.dart';

import '../controller/household_controller.dart';

class HouseholdBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HouseholdController(ownership: Get.find()));
  }
}
