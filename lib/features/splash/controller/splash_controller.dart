import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  static const _splashDuration = Duration(seconds: 2);

  @override
  void onReady() {
    super.onReady();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(_splashDuration);
    Get.offAllNamed(Routes.home);
  }
}
