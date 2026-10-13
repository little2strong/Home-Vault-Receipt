import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/utils/toast.dart';

class VerifyEmailController extends GetxController {
  VerifyEmailController({required this._auth});

  /// Stops repeated taps from flooding the inbox.
  static const resendCooldown = 30;

  final AuthRepository _auth;
  final secondsUntilResend = 0.obs;
  final isChecking = false.obs;
  Timer? _timer;

  String get email => _auth.currentUser.value?.email ?? '';

  Future<void> resend() async {
    if (secondsUntilResend.value > 0) return;
    try {
      await _auth.sendVerificationEmail();
      Toast.show('Verification email sent to $email');
      _startCooldown();
    } on AppException catch (e) {
      Toast.show(e.message);
    }
  }

  Future<void> checkVerified() async {
    isChecking.value = true;
    try {
      if (await _auth.refreshVerification()) {
        Get.offAllNamed(Routes.shell);
      } else {
        Toast.show('Not verified yet. Open the link in the email first.');
      }
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> useDifferentEmail() async {
    await _auth.signOut();
    Get.offAllNamed(Routes.createAccount);
  }

  void _startCooldown() {
    secondsUntilResend.value = resendCooldown;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsUntilResend.value--;
      if (secondsUntilResend.value <= 0) t.cancel();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
