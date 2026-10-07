import 'package:get/get.dart';

import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/usecases/delete_receipt.dart';
import '../../domain/usecases/get_receipts.dart';
import '../controllers/receipt_controller.dart';

class ReceiptBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReceiptRepository>(
      () => ReceiptRepositoryImpl(Get.find()),
      fenix: true,
    );
    Get.lazyPut(() => GetReceipts(Get.find()));
    Get.lazyPut(() => DeleteReceipt(Get.find()));
    Get.lazyPut(
      () => ReceiptController(
        getReceipts: Get.find(),
        deleteReceipt: Get.find(),
      ),
    );
  }
}
