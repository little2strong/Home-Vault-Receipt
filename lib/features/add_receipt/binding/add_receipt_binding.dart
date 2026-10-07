import 'package:get/get.dart';

import '../controller/add_receipt_controller.dart';

class AddReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddReceiptController(repository: Get.find()));
  }
}
