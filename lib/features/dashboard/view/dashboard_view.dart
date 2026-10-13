import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/receipt_tile.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/dashboard_controller.dart';

/// 07 · First receipt (empty vault) and 08 · Dashboard.
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isEmpty ? _empty() : _dashboard());
  }

  Widget _empty() {
    return VaultPage(
      header: const VaultHeader.brand(),
      title: 'Make room for\nyour first receipt.',
      subtitle: 'Start with something you bought recently.',
      actions: [
        VaultButton(
          label: AppStrings.addReceipt,
          onPressed: controller.addReceipt,
        ),
      ],
      children: const [
        ReceiptIllustration(),
        InfoCard(
          title: 'Your vault is empty',
          subtitle: 'Scan a receipt or import a PDF invoice.',
        ),
      ],
    );
  }

  Widget _dashboard() {
    final saved = controller.savedCount;
    final soon = controller.deadlinesSoon;
    final drafts = controller.draftCount;
    final waiting = controller.waitingCount;
    final missing = controller.withoutOriginalCount;

    return VaultPage(
      header: const VaultHeader.brand(),
      title: 'Everything,\nin its place.',
      subtitle: controller.greeting,
      actions: [
        VaultButton(
          label: AppStrings.addReceipt,
          onPressed: controller.addReceipt,
        ),
      ],
      children: [
        HeroCard(
          label: 'Your vault',
          value: '${Formatters.count(saved, 'receipt')}, organised.',
          caption: missing == 0
              ? 'Originals attached. Details searchable.'
              : 'Details searchable. ${Formatters.count(missing, 'record')} '
                    'without an original.',
        ),
        if (soon.isNotEmpty || drafts > 0 || waiting > 0) ...[
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: [
              if (soon.isNotEmpty)
                StatusChip(
                  label: '${Formatters.count(soon.length, 'deadline')} soon',
                  tone: ChipTone.warning,
                  onTap: controller.openReminders,
                ),
              if (drafts > 0)
                StatusChip(
                  label: '${Formatters.count(drafts, 'draft')} to review',
                  onTap: controller.openPending,
                ),
              if (waiting > 0)
                StatusChip(
                  label: '$waiting waiting to upload',
                  tone: ChipTone.warning,
                  onTap: controller.openPending,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
        ],
        if (soon.isNotEmpty) ...[
          const SectionLabel('Needs your attention'),
          for (final r in soon.take(2))
            InfoCard(
              title: r.items.length == 1 ? r.items.first.name : r.retailer,
              subtitle:
                  'Return by ${Formatters.shortDate(r.returnDeadline!)} · '
                  'user confirmed',
              trailingText: Formatters.daysRemaining(controller.daysLeft(r)),
              onTap: () => controller.openReminder(r),
            ),
        ],
        if (controller.recentlySaved.isNotEmpty) ...[
          const SectionLabel('Recently saved'),
          for (final r in controller.recentlySaved)
            ReceiptTile(receipt: r, onTap: () => controller.openReceipt(r)),
        ],
      ],
    );
  }
}
