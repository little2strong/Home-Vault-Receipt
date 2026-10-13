import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 27 · Return terms review. Used while reviewing a draft and later from a
/// saved receipt. Pops with `true` when the user confirmed or cleared.
class ReturnTermsController extends GetxController {
  ReturnTermsController({required this._receipts, required this.receiptId});

  final ReceiptRepository _receipts;
  final String receiptId;
  final chosen = Rxn<DateTime>();

  Receipt? get receipt => _receipts.byId(receiptId);

  String? get wording => receipt?.extraction?.returnWording;

  DateTime? get suggested => receipt?.extraction?.suggestedReturnDeadline;

  @override
  void onInit() {
    super.onInit();
    chosen.value = receipt?.returnDeadline ?? suggested;
  }

  /// The deadline counts as "stated on receipt" only when it is exactly the
  /// date the receipt's own wording supports.
  bool get matchesReceipt =>
      wording != null &&
      suggested != null &&
      chosen.value != null &&
      Dates.isSameDay(chosen.value!, suggested!);

  String? get error {
    final date = chosen.value;
    final r = receipt;
    if (date == null || r == null) return null;
    if (date.isBefore(Dates.dateOnly(r.purchaseDate))) {
      return 'The deadline cannot be before the purchase date.';
    }
    return null;
  }

  Future<void> pickDeadline(BuildContext context) async {
    final r = receipt;
    if (r == null) return;
    final picked = await pickDate(
      context,
      initial: chosen.value ?? r.purchaseDate,
      first: r.purchaseDate,
      last: Dates.addMonths(r.purchaseDate, 36),
      help: 'Return deadline',
    );
    if (picked != null) chosen.value = picked;
  }

  Future<void> confirm() async {
    final r = receipt;
    final date = chosen.value;
    if (r == null) return;
    if (date == null) {
      Toast.show('Choose the date printed on your receipt first.');
      return;
    }
    if (error != null) {
      Toast.show(error!);
      return;
    }
    await _receipts.upsert(
      r.copyWith(
        returnDeadline: Dates.dateOnly(date),
        deadlineSource: matchesReceipt
            ? DeadlineSource.statedOnReceipt
            : DeadlineSource.addedByUser,
      ),
    );
    Get.back(result: true);
  }

  Future<void> leaveBlank() async {
    final r = receipt;
    if (r == null) return;
    await _receipts.upsert(r.copyWith(clearReturnDeadline: true));
    Get.back(result: true);
  }
}
