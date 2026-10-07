import 'package:get/get.dart';

import '../../core/repositories/receipt_repository.dart';

/// App-wide dependencies that must outlive any single route.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ReceiptRepository(), permanent: true);
  }
}
