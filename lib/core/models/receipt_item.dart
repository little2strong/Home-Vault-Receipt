import 'product_category.dart';

/// One product line on a receipt. [lineTotal] is in minor units.
class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.name,
    required this.lineTotal,
    this.sourceDescription,
    this.quantity = 1,
    this.category = ProductCategory.other,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    id: json['id'] as String,
    name: json['name'] as String,
    lineTotal: json['line_total'] as int,
    sourceDescription: json['source_description'] as String?,
    quantity: json['quantity'] as int? ?? 1,
    category: ProductCategory.fromName(json['category'] as String?),
  );

  final String id;
  final String name;

  /// The wording printed on the receipt, kept for reference when the user
  /// renames the product (e.g. `SONY WH-1000XM5`).
  final String? sourceDescription;
  final int quantity;
  final int lineTotal;
  final ProductCategory category;

  ReceiptItem copyWith({
    String? name,
    String? sourceDescription,
    int? quantity,
    int? lineTotal,
    ProductCategory? category,
  }) => ReceiptItem(
    id: id,
    name: name ?? this.name,
    sourceDescription: sourceDescription ?? this.sourceDescription,
    quantity: quantity ?? this.quantity,
    lineTotal: lineTotal ?? this.lineTotal,
    category: category ?? this.category,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'line_total': lineTotal,
    'source_description': sourceDescription,
    'quantity': quantity,
    'category': category.name,
  };
}
