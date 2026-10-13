import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/repositories/receipt_repository.dart';

/// Every "Add a receipt" entry point goes through here so a full pilot
/// vault is explained before the user captures anything.
abstract final class CaptureLauncher {
  static void start() {
    final receipts = Get.find<ReceiptRepository>();
    Get.toNamed(receipts.isAtPilotLimit ? Routes.pilotQuota : Routes.addSource);
  }
}
