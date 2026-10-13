import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/user_account.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/widgets/pickers.dart';

/// 43 · Settings (the More tab).
class SettingsController extends GetxController {
  SettingsController({
    required this._auth,
    required this._receipts,
    required this._settings,
  });

  final AuthRepository _auth;
  final ReceiptRepository _receipts;
  final SettingsRepository _settings;

  UserAccount? get user => _auth.currentUser.value;

  int get savedCount => _receipts.savedCount;

  int get pilotLimit => ReceiptRepository.pilotLimit;

  int get remaining => (pilotLimit - savedCount).clamp(0, pilotLimit);

  int get enabledReminderTypes {
    final n = _settings.notifications.value;
    return [
      n.returnDeadlines,
      n.warrantyExpiry,
      n.maintenance,
      n.newReviewItems,
    ].where((on) => on).length;
  }

  void open(String route) => Get.toNamed(route);

  Future<void> signOut(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Sign out?',
      message:
          'Records already saved stay in your vault. Drafts and uploads '
          'waiting on this device stay here until you sign back in.',
      confirm: 'Sign out',
    );
    if (!ok) return;
    await _settings.clearSessions();
    await _auth.signOut();
    Get.offAllNamed(Routes.signIn);
  }
}
