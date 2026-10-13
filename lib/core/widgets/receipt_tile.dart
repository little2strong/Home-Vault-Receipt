import 'package:flutter/material.dart';

import '../models/receipt_model.dart';
import '../utils/formatters.dart';
import '../utils/money.dart';
import 'info_card.dart';
import 'status_chip.dart';

/// One receipt in a list: `Currys · Headphones · 2 Oct · £179.00`.
class ReceiptTile extends StatelessWidget {
  const ReceiptTile({super.key, required this.receipt, this.onTap});

  final Receipt receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = receipt.isSaved
        ? '${receipt.headline} · ${Formatters.shortDate(receipt.purchaseDate)}'
        : receipt.status.label;

    return InfoCard(
      title: receipt.retailer,
      subtitle: subtitle,
      onTap: onTap,
      trailingText: Money.format(receipt.total, currency: receipt.currency),
      trailing: receipt.isSaved
          ? null
          : const StatusChip(label: 'Pending', tone: ChipTone.warning),
    );
  }
}
