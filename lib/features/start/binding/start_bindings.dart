import 'package:get/get.dart';

import '../controller/start_controllers.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SplashController(Get.find()));
}

/// Sign in, create account and forgot password share one controller.
///
/// It is permanent on purpose: GetX deletes a controller with the route that
/// created it, so `Create account -> Sign in` (which replaces the route) would
/// dispose the text fields the sign-in page is still showing. The fields are
/// cleared on sign-out instead (see [SignInController.reset]).
class SignInBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<SignInController>()) return;
    Get.put(SignInController(Get.find()), permanent: true);
  }
}

class NotificationsBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => NotificationsController(Get.find()));
}
