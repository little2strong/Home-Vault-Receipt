import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/receipt.dart';
import '../controllers/add_receipt_controller.dart';
import '../widgets/receipt_category_icon.dart';

class AddReceiptView extends GetView<AddReceiptController> {
  const AddReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.addReceipt)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            AppTextField(
              label: AppStrings.title,
              controller: controller.titleController,
              validator: controller.validateRequired,
              prefixIcon: Icons.title_rounded,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: AppStrings.store,
              controller: controller.storeController,
              validator: controller.validateRequired,
              prefixIcon: Icons.storefront_rounded,
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: AppStrings.amount,
              controller: controller.amountController,
              validator: controller.validateAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: AppSizes.md),
            DropdownButtonFormField<ReceiptCategory>(
              initialValue: controller.category.value,
              onChanged: controller.selectCategory,
              decoration: const InputDecoration(
                labelText: AppStrings.category,
              ),
              items: [
                for (final category in ReceiptCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        ReceiptCategoryIcon(category: category, size: 28),
                        const SizedBox(width: AppSizes.sm),
                        Text(category.label),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radius),
              onTap: () => controller.pickDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: AppStrings.purchaseDate,
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Obx(
                  () => Text(Formatters.date(controller.purchaseDate.value)),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: AppStrings.note,
              controller: controller.noteController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: AppSizes.lg),
            Obx(
              () => FilledButton(
                onPressed: controller.isSaving.value ? null : controller.save,
                child: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
