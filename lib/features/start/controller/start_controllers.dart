import 'package:flutter/foundation.dart';
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
    await Future.wait([
      store.ready.future.timeout(const Duration(seconds: 8), onTimeout: () {}),
      Future<void>.delayed(const Duration(milliseconds: 700)),
    ]);
    if (store.user.value != null) {
      final next = Get.arguments;
      await afterSignIn(next: next is String ? next : null);
    } else {
      await Get.offAllNamed(kIsWeb ? Routes.webSignIn : Routes.welcome);
    }
  }
}

/// After any successful sign-in: make sure the profile exists, then home.
Future<void> afterSignIn({String? next}) async {
  final store = Get.find<VaultStore>();
  final user = store.user.value;
  if (user != null) {
    try {
      await Get.find<VaultRepository>().ensureProfile(
        displayName: user.displayName,
        email: user.email,
        timezone: kIsWeb ? null : await NotificationService.currentTimezone(),
      );
    } catch (_) {
      // Offline first launch: the cached profile arrives later.
    }
  }
  if (kIsWeb) {
    await Get.offAllNamed(next ?? Routes.webDashboard);
  } else {
    await Get.offAllNamed(Routes.shell);
  }
}

/// Page 03.
class SignInController extends GetxController {
  SignInController(this.auth);

  final AuthRepository auth;
  final email = TextEditingController();
  final password = TextEditingController();
  final busy = RxnString();
  final error = RxnString();

  /// Off: sign in to an existing account. On: create a new one.
  final creating = false.obs;
  final showPassword = false.obs;

  static const minPasswordLength = 8;

  Future<void> _run(String key, Future<void> Function() action) async {
    if (busy.value != null) return;
    busy.value = key;
    error.value = null;
    try {
      await action();
    } on AuthFailure catch (e) {
      error.value = e.message.isEmpty ? null : e.message;
    } catch (e) {
      error.value = 'Sign-in did not work. Try again.';
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

  /// Signs in, or creates the account when [creating] is on.
  Future<void> submitEmail() => _run('email', () async {
    final address = _validEmail();
    final pass = password.text;
    if (pass.isEmpty) throw const AuthFailure('Enter your password.');
    if (creating.value) {
      if (pass.length < minPasswordLength) {
        throw const AuthFailure(
          'Choose a password with at least $minPasswordLength characters.',
        );
      }
      await auth.createAccount(address, pass);
    } else {
      await auth.signInWithEmail(address, pass);
    }
    TextInput.finishAutofillContext();
    await afterSignIn();
  });

  Future<void> forgotPassword() => _run('reset', () async {
    final address = _validEmail();
    await auth.sendPasswordReset(address);
    Toast.show(
      'If $address has an account, a reset link is on its way. '
      'Check your spam folder too.',
    );
  });

  String _validEmail() {
    final address = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(address)) {
      throw const AuthFailure(
        'Enter your email address, like you@example.com.',
      );
    }
    return address;
  }

  void toggleCreating() {
    creating.toggle();
    error.value = null;
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
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
  if (kIsWeb) return;
  final service = Get.find<NotificationService>();
  final profile = Get.find<VaultStore>().profile.value;
  if (service.granted) return;
  if (profile?.notificationsAsked ?? false) return;
  await Get.toNamed(Routes.notifications);
}
