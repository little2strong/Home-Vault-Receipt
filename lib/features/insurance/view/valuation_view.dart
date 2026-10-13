import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 80 · Valuation insights. Estimates stay distinct from purchase prices.
class ValuationView extends GetView<InsuranceController> {
  const ValuationView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final byCategory = controller.valueByCategory;
    final maxValue = byCategory.values.fold(1, (m, v) => v > m ? v : m);
    final owned = controller.owned;
    final current = owned.fold(0, (s, i) => s + controller.currentEstimate(i));
    final replacement = owned.fold(
      0,
      (s, i) => s + controller.replacementEstimate(i),
    );

    return VaultPage(
      title: 'Understand recorded\nvalue.',
      subtitle: 'Estimates remain distinct from purchase prices.',
      roadmap: true,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recorded purchase values',
                style: context.textStyles.titleSmall,
              ),
              const SizedBox(height: 12),
              for (final MapEntry(key: category, value: value)
                  in byCategory.entries) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                    Text(
                      controller.money(value),
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value / maxValue,
                    minHeight: 6,
                    semanticsLabel: '${category.label} share of recorded value',
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        InfoCard(
          title: 'Purchase value',
          subtitle: controller.money(controller.recordedTotal),
        ),
        InfoCard(
          title: 'Current estimate',
          subtitle: '${controller.money(current)} · indicative',
        ),
        InfoCard(
          title: 'Replacement estimate',
          subtitle: '${controller.money(replacement)} · indicative',
        ),
      ],
    );
  }
}
