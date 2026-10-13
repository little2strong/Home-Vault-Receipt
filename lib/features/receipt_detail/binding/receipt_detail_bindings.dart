import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/edit_receipt_controller.dart';
import '../controller/receipt_detail_controller.dart';

/// Detail, original and delete share one controller per receipt id.
class ReceiptDetailBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => ReceiptDetailController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}

class EditReceiptBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => EditReceiptController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}
