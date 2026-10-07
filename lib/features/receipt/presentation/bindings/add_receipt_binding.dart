import 'package:get/get.dart';

import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/usecases/add_receipt.dart';
import '../controllers/add_receipt_controller.dart';

class AddReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiptRepository>(
      () => ReceiptRepositoryImpl(Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => AddReceipt(Get.find()));
    Get.lazyPut(() => AddReceiptController(addReceipt: Get.find()));
  }
}
