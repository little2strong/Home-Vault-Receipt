import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 76 · Insurance report
class InsuranceReportView extends GetView<InsuranceController> {
  const InsuranceReportView({super.key});

  void _preview(BuildContext context) {
    final items = controller.reportItems;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          children: [
            Text('Report preview', style: sheet.textStyles.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${Formatters.count(items.length, 'item')} · '
              '${controller.money(controller.reportValue)} '
              '(${controller.valueBasis.value.toLowerCase()})',
              style: sheet.textStyles.bodySmall,
            ),
            const SizedBox(height: AppSizes.md),
            for (final p in items)
              InfoCard(
                title: p.name,
                subtitle: [
                  p.room,
                  if (p.hasSerial) 'serial ${p.serialNumber}',
                  if (p.hasReceipt) 'receipt',
                  if (p.hasPhoto) 'photo',
                ].join(' · '),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Build an inventory\nreport.',
      subtitle: 'Select evidence to share with your insurer.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Preview report',
          onPressed: () => _preview(context),
        ),
      ],
      children: [
        Obx(
          () => Column(
            children: [
              VaultSelectField(
                label: 'Scope',
                value: controller.scope.value,
                onTap: () => controller.pickScope(context),
              ),
              VaultSelectField(
                label: 'Value basis',
                value: controller.valueBasis.value,
                onTap: () => controller.pickValueBasis(context),
              ),
            ],
          ),
        ),
        const VaultSelectField(
          label: 'Evidence',
          value: 'Photos, receipts, serial numbers',
        ),
        const VaultSelectField(
          label: 'Sensitive fields',
          value: 'Review before export',
          warning: 'Notes and buyer details are left out.',
        ),
      ],
    );
  }
}
