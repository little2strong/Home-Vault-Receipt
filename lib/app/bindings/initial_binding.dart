import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/ownership_repository.dart';
import '../../core/repositories/receipt_repository.dart';
import '../../core/repositories/settings_repository.dart';
import '../../core/services/document_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/key_value_store.dart';
import '../../core/services/receipt_save_service.dart';
import '../../core/services/sample_data.dart';
import '../../core/services/upload_service.dart';

/// App-wide dependencies that must outlive any single route.
class InitialBinding extends Bindings {
  InitialBinding({required this.store, this.seedSampleData = kDebugMode});

  final KeyValueStore store;

  /// Debug builds start each new vault with synthetic receipts so every
  /// screen has data; release builds start empty.
  final bool seedSampleData;

  @override
  void dependencies() {
    final auth = Get.put(AuthRepository(store: store), permanent: true);
    final receipts = Get.put(
      ReceiptRepository(
        store: store,
        seed: seedSampleData ? SampleData.receipts : null,
        userId: auth.currentUser.value?.id,
      ),
      permanent: true,
    );
    // Switch vaults only when the account changes. Profile edits reuse the
    // same id and must not reload over an in-flight save.
    ever(auth.currentUser, (user) {
      if (user?.id == receipts.userId) return;
      receipts.openVault(user?.id);
    });

    final uploads = Get.put(UploadService(), permanent: true);
    Get.put(SettingsRepository(store: store), permanent: true);
    Get.put(OwnershipRepository(), permanent: true);
    Get.put(DocumentService(), permanent: true);
    Get.put(ExportService(), permanent: true);
    Get.put(
      ReceiptSaveService(receipts: receipts, uploads: uploads),
      permanent: true,
    );
  }
}
