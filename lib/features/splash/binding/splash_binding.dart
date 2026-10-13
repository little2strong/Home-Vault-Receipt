import 'package:get/get.dart';

import '../controller/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager: the view never reads the controller, and a lazy one would
    // never be created, so the splash would never navigate.
    Get.put(SplashController(auth: Get.find(), settings: Get.find()));
  }
}
