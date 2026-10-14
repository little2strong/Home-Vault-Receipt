import 'package:get/get.dart';

import '../controller/start_controllers.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SplashController(Get.find()));
}

class SignInBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SignInController(Get.find()));
}

class NotificationsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => NotificationsController(Get.find()));
}
