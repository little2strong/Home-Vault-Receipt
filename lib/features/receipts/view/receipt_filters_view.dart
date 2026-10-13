import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/receipt_filters_controller.dart';

/// 12 · Receipt filters
class ReceiptFiltersView extends GetView<ReceiptFiltersController> {
  const ReceiptFiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final draft = controller.draft.value;
      final count = controller.matchCount;
      return VaultPage(
        header: VaultHeader.back(
          menu: [VaultMenuAction('Reset filters', controller.reset)],
        ),
        title: 'A smaller pile.',
        subtitle: 'Choose just the records you need.',
        actions: [
          VaultButton(
            label: count == 0
                ? 'No receipts match'
                : 'Show ${Formatters.count(count, 'receipt')}',
            onPressed: count == 0 ? null : controller.apply,
          ),
        ],
        children: [
          VaultSelectField(
            label: 'Category',
            value: controller.categoryLabel,
            onTap: () => controller.pickCategory(context),
          ),
          VaultSelectField(
            label: 'Purchase dates',
            value: controller.datesLabel,
            icon: Icons.calendar_today_outlined,
            onTap: () => controller.pickDates(context),
          ),
          if (draft.from != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: controller.clearDates,
                child: const Text('Any date'),
              ),
            ),
          VaultSelectField(
            label: 'Currency',
            value: controller.currencyLabel,
            onTap: () => controller.pickCurrency(context),
          ),
          VaultSelectField(
            label: 'Retailer',
            value: controller.retailerLabel,
            onTap: () => controller.pickRetailer(context),
          ),
          VaultSelectField(
            label: 'Return deadline',
            value: draft.deadline.label,
            onTap: () => controller.pickDeadline(context),
          ),
        ],
      );
    });
  }
}
