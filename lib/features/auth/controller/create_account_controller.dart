import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/repositories/auth_repository.dart';
import 'auth_flow.dart';

class CreateAccountController extends GetxController {
  CreateAccountController({required this._auth});

  final AuthRepository _auth;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isBusy = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  Future<void> createAccount() async {
    if (isBusy.value || !(formKey.currentState?.validate() ?? false)) return;
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final user = await _auth.createAccount(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      );
      await _auth.sendVerificationEmail();
      await AuthFlow.enterApp(user);
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isBusy.value = false;
    }
  }

  void toggleObscure() => obscurePassword.toggle();

  void openSignIn() => Get.offNamed(Routes.signIn);

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
