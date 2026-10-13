import 'package:flutter/widgets.dart';

import '../../../core/utils/dates.dart';
import '../../../core/widgets/receipt_paper.dart';

/// What the camera "sees" in this build: the sample Currys receipt.
class SampleReceiptPaper extends StatelessWidget {
  const SampleReceiptPaper({super.key});

  @override
  Widget build(BuildContext context) {
    final today = Dates.dateOnly(DateTime.now());
    return ReceiptPaper(
      retailer: 'Currys',
      date: today,
      lines: const [('Sony WH-1000XM5', 1)],
      total: 17900,
      reference: 'CR-${today.year}-10482',
      compact: true,
    );
  }
}
