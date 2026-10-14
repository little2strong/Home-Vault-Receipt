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

class CheckEmailBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => CheckEmailController(Get.find()));
}

class FinishSignInBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => FinishSignInController(Get.find()));
}

class NotificationsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => NotificationsController(Get.find()));
}
