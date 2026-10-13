import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/receipt_tile.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/receipts_controller.dart';
import '../widgets/category_pills.dart';
import '../widgets/receipt_search_field.dart';

/// 09 · Receipts, 10 · Search, 11 · Search no results.
class ReceiptsView extends GetView<ReceiptsController> {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filter = controller.filter.value;
      final results = controller.results;
      final noMatches = results.isEmpty && filter.isActive;
      final emptyVault = controller.savedCount == 0;

      final (title, subtitle) = switch ((noMatches, filter.hasQuery)) {
        (true, true) => (
          'Nothing found yet.',
          'No receipts match “${filter.query.trim()}”.',
        ),
        (true, false) => (
          'Nothing found yet.',
          'No receipts match your filters.',
        ),
        (false, true) => (
          'Find that receipt.',
          'Search shops, products or order references.',
        ),
        _ => (
          'Your receipts',
          '${Formatters.count(controller.savedCount, 'record')}, easy to find.',
        ),
      };

      return VaultPage(
        header: const VaultHeader.brand(),
        title: title,
        subtitle: subtitle,
        actions: [
          if (noMatches)
            VaultButton(label: 'Clear filters', onPressed: controller.clearAll),
          if (emptyVault)
            VaultButton(
              label: AppStrings.addReceipt,
              onPressed: controller.addReceipt,
            ),
        ],
        children: [
          ReceiptSearchField(
            controller: controller.searchController,
            onChanged: controller.onQueryChanged,
            activeFilters: filter.refinementCount,
            onFilters: controller.openFilters,
          ),
          const SizedBox(height: 12),
          CategoryPills(
            categories: controller.quickCategories,
            selected: filter.category,
            onSelected: controller.selectCategory,
            onBrowse: controller.openCategories,
          ),
          const SizedBox(height: AppSizes.sm),
          if (controller.pendingCount > 0)
            InfoCard(
              title:
                  '${Formatters.count(controller.pendingCount, 'record')} '
                  'not yet saved',
              subtitle: 'Drafts and uploads waiting on this device',
              tone: CardTone.warning,
              onTap: controller.openPending,
            ),
          if (emptyVault)
            const InfoCard(
              title: 'No saved receipts yet',
              subtitle: 'Saved receipts appear here, newest first.',
            )
          else if (noMatches) ...[
            const ReceiptIllustration(height: 170),
            const InfoCard(
              title: 'Try another search',
              subtitle: 'Search by shop, product or reference.',
            ),
            const InfoCard(
              title: 'Or clear your filters',
              subtitle: 'Your other records are still in your vault.',
            ),
          ] else
            for (final MapEntry(key: month, value: group)
                in controller.groupedResults.entries) ...[
              SectionLabel(month, upper: true),
              for (final r in group)
                ReceiptTile(receipt: r, onTap: () => controller.openReceipt(r)),
            ],
        ],
      );
    });
  }
}
