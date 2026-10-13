import 'package:get/get.dart';

import '../controller/insurance_controller.dart';

class InsuranceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InsuranceController(ownership: Get.find()));
  }
}
