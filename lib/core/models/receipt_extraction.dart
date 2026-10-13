import 'receipt_item.dart';

/// Fields the user should double-check before saving.
enum ReviewField { retailer, purchaseDate, total, returnDate }

/// What OCR read from the source document. Kept unchanged on the receipt so
/// the user's corrections stay separate from machine results.
class ReceiptExtraction {
  const ReceiptExtraction({
    this.retailer,
    this.rawDate,
    this.rawTotal,
    this.reference,
    this.returnWording,
    this.suggestedReturnDeadline,
    this.items = const [],
    this.uncertainFields = const {},
  });

  factory ReceiptExtraction.fromJson(Map<String, dynamic> json) =>
      ReceiptExtraction(
        retailer: json['retailer'] as String?,
        rawDate: json['raw_date'] as String?,
        rawTotal: json['raw_total'] as String?,
        reference: json['reference'] as String?,
        returnWording: json['return_wording'] as String?,
        suggestedReturnDeadline: json['suggested_return_deadline'] == null
            ? null
            : DateTime.parse(json['suggested_return_deadline'] as String),
        items: [
          for (final item in json['items'] as List? ?? const [])
            ReceiptItem.fromJson(item as Map<String, dynamic>),
        ],
        uncertainFields: {
          for (final f in json['uncertain_fields'] as List? ?? const [])
            ReviewField.values.byName(f as String),
        },
      );

  final String? retailer;

  /// The date exactly as printed, e.g. `02/10/26`.
  final String? rawDate;
  final String? rawTotal;
  final String? reference;

  /// The returns sentence as printed, e.g. `Returns accepted until 15
  /// October 2026.` Null when the receipt states no return terms.
  final String? returnWording;
  final DateTime? suggestedReturnDeadline;
  final List<ReceiptItem> items;
  final Set<ReviewField> uncertainFields;

  Map<String, dynamic> toJson() => {
    'retailer': retailer,
    'raw_date': rawDate,
    'raw_total': rawTotal,
    'reference': reference,
    'return_wording': returnWording,
    'suggested_return_deadline': suggestedReturnDeadline?.toIso8601String(),
    'items': [for (final item in items) item.toJson()],
    'uncertain_fields': [for (final f in uncertainFields) f.name],
  };
}
