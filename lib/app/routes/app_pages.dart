import 'package:get/get.dart';

import '../../features/add_receipt/binding/add_receipt_binding.dart';
import '../../features/add_receipt/view/add_receipt_view.dart';
import '../../features/home/binding/home_binding.dart';
import '../../features/home/view/home_view.dart';
import '../../features/splash/binding/splash_binding.dart';
import '../../features/splash/view/splash_view.dart';
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
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.addReceipt,
      page: () => const AddReceiptView(),
      binding: AddReceiptBinding(),
      fullscreenDialog: true,
    ),
  ];
}
