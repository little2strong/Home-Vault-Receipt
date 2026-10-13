import 'package:flutter/material.dart';

import '../models/receipt_model.dart';
import '../utils/formatters.dart';
import '../utils/money.dart';

/// Renders a receipt's printed lines on white paper. Used for the scanner
/// viewfinder and the "original" view.
///
/// This build stores sample documents rather than real image files, so the
/// original is drawn from the record and labelled as a sample.
class ReceiptPaper extends StatelessWidget {
  const ReceiptPaper({
    super.key,
    required this.retailer,
    required this.date,
    required this.lines,
    required this.total,
    this.currency = 'GBP',
    this.reference,
    this.compact = false,
  });

  factory ReceiptPaper.fromReceipt(Receipt r, {bool compact = false}) =>
      ReceiptPaper(
        retailer: r.retailer,
        date: r.purchaseDate,
        lines: [
          for (final item in r.items)
            (item.sourceDescription ?? item.name, item.quantity),
        ],
        total: r.total,
        currency: r.currency,
        reference: r.reference,
        compact: compact,
      );

  final String retailer;
  final DateTime date;
  final List<(String, int)> lines;
  final int total;
  final String currency;
  final String? reference;
  final bool compact;

  // Paper is always white with dark print, in both themes.
  static const _ink = Color(0xFF173B35);
  static const _faint = Color(0xFF5F6B67);

  @override
  Widget build(BuildContext context) {
    final vat = Money.splitVat(total);
    final scale = compact ? 0.85 : 1.0;
    TextStyle style(double size, {FontWeight? weight, Color color = _ink}) =>
        TextStyle(fontSize: size * scale, fontWeight: weight, color: color);
    Widget row(String left, String right, {bool bold = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: style(
                bold ? 13 : 11,
                weight: bold ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            right,
            style: style(bold ? 14 : 11, weight: bold ? FontWeight.w800 : null),
          ),
        ],
      ),
    );

    return Semantics(
      label:
          'Receipt from $retailer, ${Formatters.date(date)}, total '
          '${Money.format(total, currency: currency)}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(18 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                retailer.toUpperCase(),
                style: style(17, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                Formatters.date(date).toUpperCase(),
                style: style(8, color: _faint),
              ),
            ),
            const SizedBox(height: 16),
            for (final (name, qty) in lines.take(6)) ...[
              Text(name, style: style(11)),
              const SizedBox(height: 4),
              Text('Quantity $qty', style: style(10, color: _faint)),
              const SizedBox(height: 10),
            ],
            if (lines.length > 6)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '+ ${lines.length - 6} more lines',
                  style: style(10, color: _faint),
                ),
              ),
            if (currency == 'GBP') ...[
              row('Subtotal', Money.format(vat.subtotal)),
              row('VAT', Money.format(vat.vat)),
            ],
            const Divider(color: Color(0xFFDDE3DF), height: 16),
            row('TOTAL', Money.format(total, currency: currency), bold: true),
            const SizedBox(height: 16),
            Text('Sample source document', style: style(8, color: _faint)),
            if (reference != null)
              Text(reference!, style: style(8, color: _faint)),
          ],
        ),
      ),
    );
  }
}
