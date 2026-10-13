import 'package:get/get.dart';

import '../controller/create_account_controller.dart';
import '../controller/reset_password_controller.dart';
import '../controller/sign_in_controller.dart';
import '../controller/verify_email_controller.dart';

class SignInBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignInController(auth: Get.find()));
  }
}

class CreateAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateAccountController(auth: Get.find()));
  }
}

class VerifyEmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VerifyEmailController(auth: Get.find()));
  }
}

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ResetPasswordController(
        auth: Get.find(),
        initialEmail: Get.arguments as String?,
      ),
    );
  }
}
