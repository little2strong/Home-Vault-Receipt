import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/usecases/add_receipt.dart';

class AddReceiptController extends GetxController {
  AddReceiptController({required this._addReceipt});

  final AddReceipt _addReceipt;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final storeController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final purchaseDate = DateTime.now().obs;
  final category = ReceiptCategory.other.obs;
  final isSaving = false.obs;

  String? validateRequired(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.fieldRequired : null;

  String? validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    return (amount == null || amount <= 0) ? AppStrings.invalidAmount : null;
  }

  void selectCategory(ReceiptCategory? value) {
    if (value != null) category.value = value;
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) purchaseDate.value = picked;
  }

  Future<void> save() async {
    if (isSaving.value || !(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    final note = noteController.text.trim();
    final receipt = Receipt(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      store: storeController.text.trim(),
      amount: double.parse(amountController.text.trim()),
      purchaseDate: purchaseDate.value,
      category: category.value,
      note: note.isEmpty ? null : note,
    );

    final result = await _addReceipt(receipt);
    isSaving.value = false;

    result.when(
      ok: (saved) {
        Get.back(result: saved);
        Get.snackbar(AppStrings.success, AppStrings.receiptSaved);
      },
      err: (failure) => Get.snackbar(AppStrings.error, failure.message),
    );
  }

  @override
  void onClose() {
    titleController.dispose();
    storeController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
