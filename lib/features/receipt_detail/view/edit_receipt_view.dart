import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/edit_receipt_controller.dart';

/// 35 · Edit saved receipt
class EditReceiptView extends RouteView<EditReceiptController> {
  const EditReceiptView({super.key});

  @override
  Widget buildWith(BuildContext context, EditReceiptController controller) {
    return VaultPage(
      title: 'Update your record.',
      subtitle: 'Your corrections stay separate from OCR results.',
      actions: [
        Obx(
          () => VaultButton(
            label: 'Save changes',
            loading: controller.isSaving.value,
            onPressed: controller.save,
          ),
        ),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: Column(
            children: [
              VaultTextField(
                label: 'Retailer',
                controller: controller.retailerController,
                validator: Validators.required,
                textCapitalization: TextCapitalization.words,
              ),
              Obx(() {
                final date = controller.purchaseDate.value;
                return VaultSelectField(
                  label: 'Purchase date',
                  value: date == null ? 'Choose date' : Formatters.date(date),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickPurchaseDate(context),
                );
              }),
              VaultTextField(
                label: 'Total',
                controller: controller.totalController,
                validator: Validators.amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              Obx(
                () => VaultSelectField(
                  label: controller.hasMixedCategories
                      ? 'Category · applies to all products'
                      : 'Category',
                  value: controller.categoryLabel,
                  onTap: () => controller.pickCategory(context),
                ),
              ),
              VaultTextField(
                label: 'Receipt reference',
                hint: 'Optional',
                controller: controller.referenceController,
              ),
              VaultTextField(
                label: 'Notes',
                hint: 'e.g. Birthday gift',
                controller: controller.notesController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
