import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 42 · Reminder detail
class ReminderDetailController extends GetxController {
  ReminderDetailController({required this._receipts, required this.receiptId});

  static const scheduleOptions = <List<int>>[
    [7, 1],
    [3, 1],
    [1],
    [0],
    [],
  ];

  final ReceiptRepository _receipts;
  final String receiptId;

  final daysBefore = <int>[].obs;
  final minutes = Receipt.defaultReminderMinutes.obs;
  final isSaving = false.obs;

  Receipt? get receipt => _receipts.byId(receiptId);

  @override
  void onInit() {
    super.onInit();
    final r = receipt;
    if (r == null) return;
    daysBefore.assignAll(r.reminderDaysBefore);
    minutes.value = r.reminderMinutes;
  }

  static String describe(List<int> days) {
    if (days.isEmpty) return 'Off';
    final parts = [
      for (final d in days) d == 0 ? 'On the day' : Formatters.count(d, 'day'),
    ];
    return days.contains(0)
        ? parts.join(' and ')
        : '${parts.join(' and ')} before';
  }

  String get title {
    final r = receipt;
    if (r == null) return 'Reminder';
    return '${r.items.length == 1 ? r.items.first.name : r.retailer} return';
  }

  String get timeZone => DateTime.now().timeZoneName;

  /// Reminder days that would fall before today are skipped, so the user
  /// is told which ones will actually fire.
  String? get skippedNote {
    final r = receipt;
    final days = r?.daysUntilReturn(_receipts.today);
    if (r == null || days == null) return null;
    final skipped = daysBefore.where((d) => d > days).toList();
    if (skipped.isEmpty) return null;
    return 'The ${describe(skipped).toLowerCase()} reminder has already passed.';
  }

  Future<void> pickSchedule(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Notify me',
      options: [for (final o in scheduleOptions) describe(o)],
      selected: scheduleOptions.indexWhere(
        (o) => o.length == daysBefore.length && o.every(daysBefore.contains),
      ),
    );
    if (i != null) daysBefore.assignAll(scheduleOptions[i]);
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: minutes.value ~/ 60,
        minute: minutes.value % 60,
      ),
      helpText: 'Delivery time',
    );
    if (picked != null) minutes.value = picked.hour * 60 + picked.minute;
  }

  void changeDeadline() =>
      Get.toNamed(Routes.returnTerms, arguments: receiptId);

  Future<void> save() async {
    final r = receipt;
    if (r == null || isSaving.value) return;
    isSaving.value = true;
    try {
      await _receipts.upsert(
        r.copyWith(
          reminderDaysBefore: daysBefore.toList(),
          reminderMinutes: minutes.value,
        ),
      );
      Get.back();
      Toast.show(daysBefore.isEmpty ? 'Reminder turned off' : 'Reminder saved');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeDeadline() async {
    final r = receipt;
    if (r == null) return;
    await _receipts.upsert(r.copyWith(clearReturnDeadline: true));
    Get.back();
    Toast.show('Return deadline removed');
  }
}
