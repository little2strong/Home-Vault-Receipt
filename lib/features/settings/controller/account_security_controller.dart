import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/user_account.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 45 · Account security and 46 · Device management.
class AccountSecurityController extends GetxController {
  AccountSecurityController({required this._auth, required this._settings});

  final AuthRepository _auth;
  final SettingsRepository _settings;

  UserAccount? get user => _auth.currentUser.value;

  bool get appLock => _settings.appLock.value;

  List<DeviceSession> get devices => _settings.devices;

  String get methodsLabel {
    final methods = user?.methods.map((m) => m.label).toList() ?? const [];
    return methods.isEmpty ? 'None' : methods.join(' and ');
  }

  bool get hasPassword => user?.methods.contains(SignInMethod.email) ?? false;

  void openDevices() => Get.toNamed(Routes.devices);

  void verifyEmail() => Get.toNamed(Routes.verifyEmail);

  Future<void> setAppLock(bool enabled) => _settings.setAppLock(enabled);

  Future<void> editName(BuildContext context) async {
    final name = await promptText(context, title: 'Your name', label: 'Name');
    if (name == null || name.isEmpty) return;
    await _auth.updateName(name);
    Toast.show('Name updated');
  }

  /// Passwords change through an emailed link, so a stolen unlocked phone
  /// cannot change it silently.
  Future<void> changePassword() async {
    final email = user?.email;
    if (email == null) return;
    await _auth.sendPasswordReset(email);
    Toast.show('We sent a password change link to $email');
  }

  Future<void> revoke(BuildContext context, DeviceSession device) async {
    final ok = await confirmDialog(
      context,
      title: 'Sign out ${device.name}?',
      message: 'That device will need to sign in again.',
      confirm: 'Sign out',
      destructive: true,
    );
    if (!ok) return;
    await _settings.revokeDevice(device.id);
    Toast.show('${device.name} signed out');
  }

  Future<void> revokeOthers(BuildContext context) async {
    if (!devices.any((d) => !d.isCurrent)) {
      Toast.show('Only this device is signed in.');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Sign out other devices?',
      message: 'Every device except this one will need to sign in again.',
      confirm: 'Sign out others',
      destructive: true,
    );
    if (!ok) return;
    await _settings.revokeOtherDevices();
    Toast.show('Other devices signed out');
  }

  Future<void> secureAccount(BuildContext context) async {
    await _settings.revokeOtherDevices();
    await changePassword();
  }
}
