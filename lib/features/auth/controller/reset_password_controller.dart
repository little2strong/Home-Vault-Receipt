import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/repositories/auth_repository.dart';

class ResetPasswordController extends GetxController {
  ResetPasswordController({required this._auth, String? initialEmail})
    : emailController = TextEditingController(text: initialEmail);

  final AuthRepository _auth;

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController;
  final isBusy = false.obs;
  final sentTo = RxnString();
  final errorMessage = RxnString();

  Future<void> sendLink() async {
    if (isBusy.value || !(formKey.currentState?.validate() ?? false)) return;
    isBusy.value = true;
    errorMessage.value = null;
    try {
      final email = emailController.text.trim();
      await _auth.sendPasswordReset(email);
      sentTo.value = email;
    } on AppException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
