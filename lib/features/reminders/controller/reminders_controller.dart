import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 41 · Return reminders
class RemindersController extends GetxController {
  RemindersController({required this._receipts, required this._settings});

  final ReceiptRepository _receipts;
  final SettingsRepository _settings;

  List<Receipt> get open => _receipts.openDeadlines();

  bool get remindersOn => _settings.notifications.value.returnDeadlines;

  String titleFor(Receipt r) =>
      r.items.length == 1 ? r.items.first.name : '${r.retailer} purchase';

  String subtitleFor(Receipt r) {
    final days = r.daysUntilReturn(_receipts.today) ?? 0;
    final left = switch (days) {
      0 => 'last day',
      1 => '1 day remaining',
      _ => '$days days remaining',
    };
    return '${Formatters.shortDate(r.returnDeadline!)} · $left';
  }

  void openReminder(Receipt r) =>
      Get.toNamed(Routes.reminderDetail, arguments: r.id);

  void openNotificationSettings() => Get.toNamed(Routes.notificationSettings);

  /// Lets the user attach a date they can verify to a receipt that has none.
  Future<void> addVerifiedDate(BuildContext context) async {
    final candidates = _receipts.saved
        .where((r) => r.returnDeadline == null)
        .toList();
    if (candidates.isEmpty) {
      Toast.show('Every saved receipt already has a return deadline.');
      return;
    }
    final i = await showOptionSheet(
      context,
      title: 'Which receipt?',
      options: [
        for (final r in candidates)
          '${r.retailer} · ${r.headline} · ${Formatters.shortDate(r.purchaseDate)}',
      ],
    );
    if (i != null) {
      Get.toNamed(Routes.returnTerms, arguments: candidates[i].id);
    }
  }
}
