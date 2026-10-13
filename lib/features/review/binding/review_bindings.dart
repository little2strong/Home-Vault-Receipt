import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../controller/edit_item_controller.dart';
import '../controller/manual_receipt_controller.dart';
import '../controller/return_terms_controller.dart';
import '../controller/review_controller.dart';

/// Summary, products, date and duplicate screens share one controller per
/// draft, tagged by the draft id.
class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => ReviewController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}

class EditItemBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as ItemEditArgs;
    Get.lazyPut(() => EditItemController(args: args), tag: currentRouteTag);
  }
}

class ReturnTermsBinding extends Bindings {
  @override
  void dependencies() {
    final id = Get.arguments as String;
    Get.lazyPut(
      () => ReturnTermsController(receipts: Get.find(), receiptId: id),
      tag: currentRouteTag,
    );
  }
}

class ManualReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ManualReceiptController(receipts: Get.find()));
  }
}
