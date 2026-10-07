import 'package:get/get.dart';

import '../../features/receipt/data/datasources/receipt_local_data_source.dart';

/// App-wide dependencies that must outlive any single route.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ReceiptLocalDataSource>(
      ReceiptLocalDataSourceImpl(),
      permanent: true,
    );
  }
}
