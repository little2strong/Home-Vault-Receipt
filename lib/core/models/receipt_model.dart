enum ReceiptCategory {
  electronics('Electronics'),
  appliances('Appliances'),
  furniture('Furniture'),
  groceries('Groceries'),
  other('Other');

  const ReceiptCategory(this.label);

  final String label;
}

class Receipt {
  const Receipt({
    required this.id,
    required this.title,
    required this.store,
    required this.amount,
    required this.purchaseDate,
    required this.category,
    this.note,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json['id'] as String,
        title: json['title'] as String,
        store: json['store'] as String,
        amount: (json['amount'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        category: ReceiptCategory.values.byName(json['category'] as String),
        note: json['note'] as String?,
      );

  final String id;
  final String title;
  final String store;
  final double amount;
  final DateTime purchaseDate;
  final ReceiptCategory category;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'store': store,
        'amount': amount,
        'purchase_date': purchaseDate.toIso8601String(),
        'category': category.name,
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Receipt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
