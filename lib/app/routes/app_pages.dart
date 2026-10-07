import 'package:get/get.dart';

import '../../features/receipt/presentation/bindings/add_receipt_binding.dart';
import '../../features/receipt/presentation/bindings/receipt_binding.dart';
import '../../features/receipt/presentation/views/add_receipt_view.dart';
import '../../features/receipt/presentation/views/receipt_view.dart';
import '../../features/splash/presentation/bindings/splash_binding.dart';
import '../../features/splash/presentation/views/splash_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static const initial = Routes.splash;

  static final pages = <GetPage>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.receipts,
      page: () => const ReceiptView(),
      binding: ReceiptBinding(),
    ),
    GetPage(
      name: Routes.addReceipt,
      page: () => const AddReceiptView(),
      binding: AddReceiptBinding(),
      fullscreenDialog: true,
    ),
  ];
}
