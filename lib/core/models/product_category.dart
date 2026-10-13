/// Categories belong to individual products, not receipts: one IKEA receipt
/// can hold furniture and groceries.
enum ProductCategory {
  electronics('Electronics'),
  home('Home & furniture', shortLabel: 'Home'),
  appliances('Appliances'),
  groceries('Groceries'),
  clothing('Clothing'),
  other('Other');

  const ProductCategory(this.label, {this._shortLabel});

  final String label;
  final String? _shortLabel;

  String get shortLabel => _shortLabel ?? label;

  static ProductCategory fromName(String? name) => ProductCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ProductCategory.other);
}
