import '../utils/dates.dart';
import '../utils/money.dart';
import 'product_category.dart';
import 'receipt_model.dart';

enum DeadlineFilter {
  any('Any'),
  soon('Within 14 days'),
  open('Return still open'),
  none('No return deadline');

  const DeadlineFilter(this.label);

  final String label;
}

/// Search text plus the refinements from the filter screen. Immutable so the
/// filter screen can edit a copy and preview its result count.
class ReceiptFilter {
  const ReceiptFilter({
    this.query = '',
    this.category,
    this.from,
    this.to,
    this.currency,
    this.retailer,
    this.deadline = DeadlineFilter.any,
  });

  static const soonWindowDays = 14;

  final String query;
  final ProductCategory? category;
  final DateTime? from;
  final DateTime? to;
  final String? currency;
  final String? retailer;
  final DeadlineFilter deadline;

  bool get hasQuery => query.trim().isNotEmpty;

  int get refinementCount => [
    category != null,
    from != null || to != null,
    currency != null,
    retailer != null,
    deadline != DeadlineFilter.any,
  ].where((active) => active).length;

  bool get isActive => hasQuery || refinementCount > 0;

  bool matches(Receipt r, DateTime today) {
    if (category != null && !r.categories.contains(category)) return false;

    final day = Dates.dateOnly(r.purchaseDate);
    if (from != null && day.isBefore(Dates.dateOnly(from!))) return false;
    if (to != null && day.isAfter(Dates.dateOnly(to!))) return false;
    if (currency != null && r.currency != currency) return false;
    if (retailer != null &&
        r.retailer.toLowerCase() != retailer!.toLowerCase()) {
      return false;
    }

    final days = r.daysUntilReturn(today);
    final deadlineOk = switch (deadline) {
      DeadlineFilter.any => true,
      DeadlineFilter.soon =>
        days != null && days >= 0 && days <= soonWindowDays,
      DeadlineFilter.open => days != null && days >= 0,
      DeadlineFilter.none => days == null,
    };
    return deadlineOk && _matchesQuery(r);
  }

  /// Every word must appear somewhere: shop, product, printed description,
  /// order reference, notes, category or amount.
  bool _matchesQuery(Receipt r) {
    final words = query.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return true;

    final haystack = [
      r.retailer,
      r.reference ?? '',
      r.notes ?? '',
      Money.format(r.total, currency: r.currency),
      for (final item in r.items) ...[
        item.name,
        item.sourceDescription ?? '',
        item.category.label,
      ],
    ].join(' ').toLowerCase();
    return words.every(haystack.contains);
  }

  ReceiptFilter copyWith({
    String? query,
    ProductCategory? category,
    DateTime? from,
    DateTime? to,
    String? currency,
    String? retailer,
    DeadlineFilter? deadline,
    bool clearCategory = false,
    bool clearDates = false,
    bool clearCurrency = false,
    bool clearRetailer = false,
  }) => ReceiptFilter(
    query: query ?? this.query,
    category: clearCategory ? null : (category ?? this.category),
    from: clearDates ? null : (from ?? this.from),
    to: clearDates ? null : (to ?? this.to),
    currency: clearCurrency ? null : (currency ?? this.currency),
    retailer: clearRetailer ? null : (retailer ?? this.retailer),
    deadline: deadline ?? this.deadline,
  );

  /// Keeps the search text, drops every refinement.
  ReceiptFilter cleared() => ReceiptFilter(query: query);
}
