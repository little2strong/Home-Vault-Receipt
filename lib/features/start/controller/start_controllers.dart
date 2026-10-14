import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // A sign-in link may have opened the app; DeepLinks routes it.
    if (Get.currentRoute == Routes.finishSignIn) return;
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
  final busy = RxnString();
  final error = RxnString();

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

  Future<void> emailLink() => _run('email', () async {
    final address = email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(address)) {
      throw const AuthFailure(
        'Enter your email address, like you@example.com.',
      );
    }
    await auth.sendEmailLink(address);
    await Get.toNamed(Routes.checkEmail, arguments: address);
  });

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}

/// Page 04.
class CheckEmailController extends GetxController {
  CheckEmailController(this.auth);

  final AuthRepository auth;
  late final String email = (Get.arguments as String?) ?? '';
  final cooldown = 0.obs;
  Timer? _timer;

  Future<void> openMail() async {
    final uri = GetPlatform.isIOS
        ? Uri.parse('message://')
        : Uri.parse('mailto:');
    if (!await launchUrl(uri)) {
      Toast.show('Open your email app to find the link.');
    }
  }

  Future<void> resend() async {
    if (cooldown.value > 0) return;
    try {
      await auth.sendEmailLink(email);
      Toast.show('Sent again. Check your inbox and spam folder.');
      cooldown.value = 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        cooldown.value--;
        if (cooldown.value <= 0) t.cancel();
      });
    } on AuthFailure catch (e) {
      Toast.show(e.message);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

/// Completes email-link sign-in on this device.
class FinishSignInController extends GetxController {
  FinishSignInController(this.auth);

  final AuthRepository auth;
  final email = TextEditingController();
  final needsEmail = false.obs;
  final busy = true.obs;
  final error = RxnString();
  late final String link = _link();

  String _link() {
    final arg = Get.arguments;
    if (arg is String) return arg;
    return Uri.base.toString();
  }

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    if (!auth.isEmailLink(link)) {
      busy.value = false;
      error.value = 'This link is not a Home Vault sign-in link.';
      return;
    }
    final pending = await auth.pendingEmail();
    if (pending == null) {
      busy.value = false;
      needsEmail.value = true;
      return;
    }
    await finish(pending);
  }

  Future<void> finish([String? address]) async {
    busy.value = true;
    error.value = null;
    try {
      await auth.completeEmailLink(link, email: address ?? email.text.trim());
      await afterSignIn();
    } on AuthFailure catch (e) {
      error.value = e.message;
      needsEmail.value = true;
    } finally {
      busy.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
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
