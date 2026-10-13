import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/product_category.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 35 · Edit saved receipt. Corrections are stored on the record; the
/// original OCR extraction is left untouched.
class EditReceiptController extends GetxController {
  EditReceiptController({required this._receipts, required this.receiptId});

  final ReceiptRepository _receipts;
  final String receiptId;

  final formKey = GlobalKey<FormState>();
  final retailerController = TextEditingController();
  final totalController = TextEditingController();
  final notesController = TextEditingController();
  final referenceController = TextEditingController();
  final purchaseDate = Rxn<DateTime>();

  /// Null means "leave each product's category as it is".
  final category = Rxn<ProductCategory>();
  final isSaving = false.obs;

  Receipt? get receipt => _receipts.byId(receiptId);

  @override
  void onInit() {
    super.onInit();
    final r = receipt;
    if (r == null) return;
    retailerController.text = r.retailer;
    totalController.text = Money.toInput(r.total);
    notesController.text = r.notes ?? '';
    referenceController.text = r.reference ?? '';
    purchaseDate.value = r.purchaseDate;
    if (r.categories.length == 1) category.value = r.categories.first;
  }

  bool get hasMixedCategories => (receipt?.categories.length ?? 0) > 1;

  String get categoryLabel =>
      category.value?.label ??
      (hasMixedCategories ? 'Mixed · keep as is' : 'Other');

  Future<void> pickPurchaseDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: purchaseDate.value ?? _receipts.today,
      last: _receipts.today,
      help: 'Purchase date',
    );
    if (picked != null) purchaseDate.value = picked;
  }

  Future<void> pickCategory(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: hasMixedCategories ? 'Apply to all products' : 'Category',
      options: [for (final c in ProductCategory.values) c.label],
      selected: category.value?.index,
    );
    if (i != null) category.value = ProductCategory.values[i];
  }

  Future<void> save() async {
    final r = receipt;
    if (r == null || isSaving.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final returnDeadline = r.returnDeadline;
    if (returnDeadline != null &&
        Dates.dateOnly(
          returnDeadline,
        ).isBefore(Dates.dateOnly(purchaseDate.value!))) {
      Toast.show('The purchase date is after the return deadline. Check both.');
      return;
    }

    isSaving.value = true;
    try {
      final notes = notesController.text.trim();
      final reference = referenceController.text.trim();
      final chosen = category.value;
      await _receipts.upsert(
        r.copyWith(
          retailer: retailerController.text.trim(),
          total: Money.parse(totalController.text),
          purchaseDate: purchaseDate.value,
          notes: notes,
          clearNotes: notes.isEmpty,
          reference: reference,
          clearReference: reference.isEmpty,
          items: chosen == null
              ? null
              : [for (final i in r.items) i.copyWith(category: chosen)],
        ),
      );
      Get.back();
      Toast.show(AppStrings.receiptUpdated);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    retailerController.dispose();
    totalController.dispose();
    notesController.dispose();
    referenceController.dispose();
    super.onClose();
  }
}
