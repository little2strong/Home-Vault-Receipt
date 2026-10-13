import 'dart:convert';

import '../models/receipt_model.dart';
import '../utils/dates.dart';
import '../utils/money.dart';

enum ExportScope {
  all('All receipts'),
  last12Months('Last 12 months'),
  thisYear('This year');

  const ExportScope(this.label);

  final String label;
}

enum ExportFormat {
  csvAndJson('CSV and JSON'),
  csv('CSV only'),
  json('JSON only');

  const ExportFormat(this.label);

  final String label;
}

enum LinkExpiry {
  day('24 hours', Duration(hours: 24)),
  week('7 days', Duration(days: 7));

  const LinkExpiry(this.label, this.duration);

  final String label;
  final Duration duration;
}

class ExportRequest {
  const ExportRequest({
    this.scope = ExportScope.all,
    this.format = ExportFormat.csvAndJson,
    this.includeOriginals = true,
    this.expiry = LinkExpiry.day,
  });

  final ExportScope scope;
  final ExportFormat format;
  final bool includeOriginals;
  final LinkExpiry expiry;

  ExportRequest copyWith({
    ExportScope? scope,
    ExportFormat? format,
    bool? includeOriginals,
    LinkExpiry? expiry,
  }) => ExportRequest(
    scope: scope ?? this.scope,
    format: format ?? this.format,
    includeOriginals: includeOriginals ?? this.includeOriginals,
    expiry: expiry ?? this.expiry,
  );
}

class ExportArchive {
  const ExportArchive({
    required this.receiptCount,
    required this.sizeBytes,
    required this.expiresAt,
    required this.includesOriginals,
    this.csv,
    this.json,
  });

  final int receiptCount;
  final int sizeBytes;
  final DateTime expiresAt;
  final bool includesOriginals;
  final String? csv;
  final String? json;
}

class ExportService {
  List<Receipt> select(List<Receipt> saved, ExportScope scope, DateTime now) {
    final today = Dates.dateOnly(now);
    return switch (scope) {
      ExportScope.all => saved,
      ExportScope.last12Months => [
        for (final r in saved)
          if (!r.purchaseDate.isBefore(Dates.addMonths(today, -12))) r,
      ],
      ExportScope.thisYear => [
        for (final r in saved)
          if (r.purchaseDate.year == today.year) r,
      ],
    };
  }

  ExportArchive build(
    List<Receipt> saved,
    ExportRequest request,
    DateTime now,
  ) {
    final receipts = select(saved, request.scope, now);
    final csv = request.format == ExportFormat.json ? null : toCsv(receipts);
    final json = request.format == ExportFormat.csv ? null : toJson(receipts);
    final originals = request.includeOriginals
        ? receipts.fold<int>(
            0,
            (sum, r) => sum + r.documents.fold(0, (s, d) => s + d.sizeBytes),
          )
        : 0;
    return ExportArchive(
      receiptCount: receipts.length,
      sizeBytes:
          utf8.encode(csv ?? '').length +
          utf8.encode(json ?? '').length +
          originals,
      expiresAt: now.add(request.expiry.duration),
      includesOriginals: request.includeOriginals,
      csv: csv,
      json: json,
    );
  }

  /// One row per product line, so spreadsheets can total by category.
  String toCsv(List<Receipt> receipts) {
    final rows = <List<String>>[
      [
        'receipt_id',
        'retailer',
        'purchase_date',
        'currency',
        'receipt_total',
        'reference',
        'return_deadline',
        'product',
        'quantity',
        'line_total',
        'category',
        'notes',
      ],
    ];
    for (final r in receipts) {
      final base = [
        r.id,
        r.retailer,
        _isoDate(r.purchaseDate),
        r.currency,
        Money.toInput(r.total),
        r.reference ?? '',
        r.returnDeadline == null ? '' : _isoDate(r.returnDeadline!),
      ];
      if (r.items.isEmpty) {
        rows.add([...base, '', '', '', '', r.notes ?? '']);
      }
      for (final item in r.items) {
        rows.add([
          ...base,
          item.name,
          '${item.quantity}',
          Money.toInput(item.lineTotal),
          item.category.label,
          r.notes ?? '',
        ]);
      }
    }
    return rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
  }

  String toJson(List<Receipt> receipts) => const JsonEncoder.withIndent(
    '  ',
  ).convert([for (final r in receipts) r.toJson()]);

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _csvCell(String value) {
    // Leading =, +, - or @ would run as a formula in spreadsheet apps.
    final safe = value.startsWith(RegExp('[=+\\-@]')) ? "'$value" : value;
    final needsQuotes = safe.contains(RegExp('[",\r\n]'));
    return needsQuotes ? '"${safe.replaceAll('"', '""')}"' : safe;
  }
}
