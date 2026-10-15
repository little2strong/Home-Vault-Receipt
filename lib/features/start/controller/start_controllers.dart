import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/feedback.dart';

/// Page 01: shows the logo while the first auth state arrives.
class SplashController extends GetxController {
  SplashController(this.store);

  final VaultStore store;

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    // Hold the mark briefly, but never leave a signed-in person on the
    // welcome screen just because the first auth event was slow.
    const minimum = Duration(milliseconds: 900);
    final started = DateTime.now();
    try {
      await store.ready.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // No auth answer. Continue as signed out.
    }
    final remaining = minimum - DateTime.now().difference(started);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (isClosed) return;
    if (store.user.value != null) {
      await afterSignIn();
    } else {
      await Get.offAllNamed(Routes.welcome);
    }
  }
}

/// After any successful sign-in: make sure the profile exists, then home.
Future<void> afterSignIn({String? displayName}) async {
  final store = Get.find<VaultStore>();
  final user = store.user.value;
  if (user != null) {
    try {
      await Get.find<VaultRepository>().ensureProfile(
        displayName: displayName ?? user.displayName,
        email: user.email,
        timezone: await NotificationService.currentTimezone(),
      );
    } catch (_) {
      // Offline first launch: the cached profile arrives later.
    }
  }
  await Get.offAllNamed(Routes.shell);
}

/// Signs out and goes back to the welcome screen.
Future<void> signOutOfVault() async {
  await Get.find<AuthRepository>().signOut();
  await Get.offAllNamed(Routes.welcome);
}

Future<void> confirmSignOut(BuildContext context) async {
  final ok = await Pickers.confirm(
    context,
    title: 'Sign out?',
    message:
        'Drafts not yet saved stay on this phone for when you sign back in.',
    action: 'Sign out',
  );
  if (!ok) return;
  await signOutOfVault();
}

/// Page 03, create account and forgot password.
class SignInController extends GetxController {
  SignInController(this.auth);

  final AuthRepository auth;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final busy = RxnString();
  final error = RxnString();
  final showPassword = false.obs;

  final nameError = RxnString();
  final emailError = RxnString();
  final passwordError = RxnString();
  final confirmError = RxnString();

  /// The address a reset link went to; null until one is sent.
  final resetSentTo = RxnString();

  /// Seconds before another reset link can be requested.
  final resendIn = 0.obs;
  Timer? _resendTimer;

  static const resendCooldown = 60;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  Future<void> _run(String key, Future<void> Function() action) async {
    if (busy.value != null) return;
    busy.value = key;
    error.value = null;
    try {
      await action();
    } on AuthFailure catch (e) {
      error.value = e.message.isEmpty ? null : e.message;
    } catch (e) {
      error.value = 'That did not work. Try again.';
    } finally {
      busy.value = null;
    }
  }

  Future<void> apple() => _run('apple', () async {
    await auth.signInWithApple();
    await afterSignIn();
  });

  Future<void> google() => _run('google', () async {
    await auth.signInWithGoogle();
    await afterSignIn();
  });

  /// Signs in, or creates the account when [create] is set.
  Future<void> submitEmail({bool create = false}) async {
    if (busy.value != null) return;
    if (!_validate(create: create)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await _run('email', () async {
      final address = email.text.trim();
      if (create) {
        final displayName = _cleanName();
        await auth.createAccount(
          address,
          password.text,
          displayName: displayName,
        );
        TextInput.finishAutofillContext();
        await afterSignIn(displayName: displayName);
      } else {
        await auth.signInWithEmail(address, password.text);
        TextInput.finishAutofillContext();
        await afterSignIn();
      }
    });
  }

  bool _validate({required bool create}) {
    _clearMessages();
    final address = email.text.trim();
    final pass = password.text;
    if (create && _cleanName().isEmpty) nameError.value = 'Enter your name.';
    emailError.value = _emailProblem(address);
    if (pass.isEmpty) {
      passwordError.value = create
          ? 'Choose a password.'
          : 'Enter your password.';
    }
    if (create && confirmPassword.text != pass) {
      confirmError.value = 'Passwords do not match.';
    }
    return nameError.value == null &&
        emailError.value == null &&
        passwordError.value == null &&
        confirmError.value == null;
  }

  String? _emailProblem(String address) {
    if (address.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(address)) {
      return 'That does not look like an email, e.g. you@example.com.';
    }
    return null;
  }

  String _cleanName() => name.text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Emails a reset link to the address in the email field.
  Future<void> sendReset() async {
    if (busy.value != null) return;
    _clearMessages();
    final address = email.text.trim();
    emailError.value = _emailProblem(address);
    if (emailError.value != null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await _run('reset', () async {
      await auth.sendPasswordReset(address);
      resetSentTo.value = address;
      _startResendCooldown();
    });
  }

  Future<void> resendReset() async {
    final address = resetSentTo.value;
    if (address == null || resendIn.value > 0) return;
    await _run('reset', () async {
      await auth.sendPasswordReset(address);
      _startResendCooldown();
      Toast.show('Sent again to $address.');
    });
  }

  /// Back to the email field on the forgot password screen.
  void useDifferentEmail() {
    _clearMessages();
    resetSentTo.value = null;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendIn.value = resendCooldown;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      resendIn.value--;
      if (resendIn.value <= 0) t.cancel();
    });
  }

  void _clearMessages() {
    error.value = null;
    nameError.value = null;
    emailError.value = null;
    passwordError.value = null;
    confirmError.value = null;
  }

  void openSignUp() {
    _clearMessages();
    Get.toNamed(Routes.signUp);
  }

  void openSignIn() {
    _clearMessages();
    if (Get.previousRoute == Routes.signIn) {
      Get.back();
      return;
    }
    Get.offNamed(Routes.signIn);
  }

  Future<void> openForgotPassword() async {
    _clearMessages();
    resetSentTo.value = null;
    await Get.toNamed(Routes.forgotPassword);
    _clearMessages();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}

/// Page 05: explains reminders before the system prompt.
class NotificationsController extends GetxController {
  NotificationsController(this.notifications);

  final NotificationService notifications;
  final busy = false.obs;

  Future<void> turnOn() async {
    busy.value = true;
    final granted = await notifications.requestPermission();
    busy.value = false;
    if (!granted) {
      Toast.show('Reminders are off. You can turn them on in Settings.');
    }
    Get.back(result: granted);
  }

  Future<void> notNow() async {
    try {
      await Get.find<VaultRepository>().updateProfile({
        'notificationsAsked': true,
      });
    } catch (_) {}
    Get.back(result: false);
  }
}

/// Opens the explainer the first time a reminder is set, never before.
Future<void> askForRemindersOnce() async {
  final service = Get.find<NotificationService>();
  final profile = Get.find<VaultStore>().profile.value;
  if (service.granted) return;
  if (profile?.notificationsAsked ?? false) return;
  await Get.toNamed(Routes.notifications);
}
