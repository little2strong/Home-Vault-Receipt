import 'package:get/get.dart';

import '../../core/data/auth_repository.dart';
import '../../core/data/file_store.dart';
import '../../core/data/vault_repository.dart';
import '../../core/data/vault_store.dart';
import '../../core/services/capture_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/draft_store.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/receipt_saver.dart';
import '../../core/services/text_recognition_service.dart';

/// App-wide services, alive for the whole session.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    final auth = Get.put(AuthRepository(), permanent: true);
    final files = Get.put<FileStore>(FirebaseFileStore(), permanent: true);
    final store = Get.put(VaultStore(auth), permanent: true);
    final repo = Get.put(
      VaultRepository(
        uid: () => store.uid ?? (throw const VaultFailure('Signed out')),
        files: files,
      ),
      permanent: true,
    );
    final connectivity = Get.put(ConnectivityService(), permanent: true);
    final capture = Get.put(CaptureService(), permanent: true);
    Get
      ..put(TextRecognitionService(), permanent: true)
      ..put(
        ReceiptSaver(
          store: store,
          repo: repo,
          drafts: DraftStore(),
          capture: capture,
          connectivity: connectivity,
        ),
        permanent: true,
      )
      ..put(NotificationService(store, repo), permanent: true);
  }
}
