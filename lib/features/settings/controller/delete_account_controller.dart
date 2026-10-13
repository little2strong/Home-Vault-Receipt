import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 50 · Account deletion. Requires the password again before anything is
/// removed.
class DeleteAccountController extends GetxController {
  DeleteAccountController({
    required this._auth,
    required this._receipts,
    required this._settings,
  });

  final AuthRepository _auth;
  final ReceiptRepository _receipts;
  final SettingsRepository _settings;

  final isDeleting = false.obs;

  int get recordCount => _receipts.receipts.length;

  void exportFirst() => Get.toNamed(Routes.exportData);

  Future<void> deleteAccount(BuildContext context) async {
    if (isDeleting.value) return;
    final password = await promptText(
      context,
      title: 'Confirm it is you',
      label: 'Password',
      confirm: 'Delete account',
      obscure: true,
    );
    if (password == null) return;

    isDeleting.value = true;
    try {
      await _auth.reauthenticate(password);
      await _receipts.deleteAll();
      await _settings.clearSessions();
      await _auth.deleteAccount();
    } on AppException catch (e) {
      isDeleting.value = false;
      Toast.show(e.message);
      return;
    }
    Get.offAllNamed(Routes.signIn);
    Toast.show('Your account and live records were deleted');
  }
}
