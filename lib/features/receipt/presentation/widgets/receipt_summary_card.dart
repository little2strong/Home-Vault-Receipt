import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';

class ReceiptSummaryCard extends StatelessWidget {
  const ReceiptSummaryCard({
    super.key,
    required this.totalAmount,
    required this.count,
  });

  final double totalAmount;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: AppStrings.totalSpent,
              value: Formatters.currency(totalAmount),
              color: onPrimary,
            ),
          ),
          _SummaryItem(
            label: AppStrings.receiptsCount,
            value: '$count',
            color: onPrimary,
            alignment: CrossAxisAlignment.end,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
