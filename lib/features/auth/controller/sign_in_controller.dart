import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/models/user_account.dart';
import '../../../core/repositories/auth_repository.dart';
import 'auth_flow.dart';

class SignInController extends GetxController {
  SignInController({required this._auth});

  final AuthRepository _auth;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isBusy = false.obs;
  final obscurePassword = true.obs;
  final errorMessage = RxnString();

  Future<void> signIn() async {
    if (isBusy.value || !(formKey.currentState?.validate() ?? false)) return;
    await _run(
      () => _auth.signIn(emailController.text, passwordController.text),
    );
  }

  Future<void> signInWith(SignInMethod method) =>
      _run(() => _auth.signInWithProvider(method));

  void toggleObscure() => obscurePassword.toggle();

  void openCreateAccount() => Get.toNamed(Routes.createAccount);

  void openResetPassword() =>
      Get.toNamed(Routes.resetPassword, arguments: emailController.text.trim());

  Future<void> _run(Future<UserAccount> Function() action) async {
    isBusy.value = true;
    errorMessage.value = null;
    try {
      await AuthFlow.enterApp(await action());
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
