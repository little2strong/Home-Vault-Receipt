import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/manual_receipt_controller.dart';

/// 29 · Manual receipt
class ManualReceiptView extends GetView<ManualReceiptController> {
  const ManualReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Add the essentials.',
      subtitle: 'Optional details can be completed later.',
      actions: [
        Obx(
          () => VaultButton(
            label: 'Save receipt',
            loading: controller.isBusy.value,
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
                hint: 'Enter shop name',
                controller: controller.retailerController,
                validator: Validators.required,
                textCapitalization: TextCapitalization.words,
              ),
              Obx(() {
                final date = controller.purchaseDate.value;
                return VaultSelectField(
                  label: 'Purchase date',
                  value: date == null ? 'Choose date' : Formatters.date(date),
                  placeholder: date == null,
                  warning: controller.dateError.value,
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickPurchaseDate(context),
                );
              }),
              VaultTextField(
                label: 'Total',
                hint: 'Enter amount',
                controller: controller.totalController,
                validator: Validators.amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              Obx(
                () => VaultSelectField(
                  label: 'Currency',
                  value: controller.currency.value,
                  onTap: () => controller.pickCurrency(context),
                ),
              ),
            ],
          ),
        ),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in controller.items)
                InfoCard(
                  title: item.name,
                  subtitle: '${item.quantity} · ${item.category.shortLabel}',
                  trailingText: Money.format(
                    item.lineTotal,
                    currency: controller.currency.value,
                  ),
                  onTap: () => controller.editProduct(item),
                ),
              InfoCard(
                title: controller.items.isEmpty
                    ? 'Add a product'
                    : 'Add another product',
                subtitle: 'Optional',
                tone: CardTone.tonal,
                onTap: controller.editProduct,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
