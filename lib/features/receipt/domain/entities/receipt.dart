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

  final String id;
  final String title;
  final String store;
  final double amount;
  final DateTime purchaseDate;
  final ReceiptCategory category;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Receipt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
