import 'package:get/get.dart';

import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/item.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/search.dart';

enum WarrantyFilter {
  any('Any'),
  active('Active'),
  ending('Ending in 3 months'),
  expired('Expired'),
  none('No warranty');

  const WarrantyFilter(this.label);
  final String label;
}

enum BoughtFilter {
  days30('Last 30 days'),
  year('Last year'),
  any('Any time');

  const BoughtFilter(this.label);
  final String label;
}

enum ProductSort {
  newest('Newest first'),
  oldest('Oldest first'),
  priceHigh('Price, high to low'),
  name('Name, A to Z');

  const ProductSort(this.label);
  final String label;
}

/// Filters for Products (19) and the Filters sheet (20).
class ProductFilters {
  const ProductFilters({
    this.roomId,
    this.purpose,
    this.type,
    this.category,
    this.status,
    this.carId,
    this.inHome = false,
    this.warranty = WarrantyFilter.any,
    this.bought = BoughtFilter.any,
  });

  final String? roomId;
  final Purpose? purpose;
  final ItemType? type;
  final Category? category;
  final ItemStatus? status;
  final String? carId;
  final bool inHome;
  final WarrantyFilter warranty;
  final BoughtFilter bought;

  bool get isEmpty =>
      roomId == null &&
      purpose == null &&
      type == null &&
      category == null &&
      status == null &&
      carId == null &&
      !inHome &&
      warranty == WarrantyFilter.any &&
      bought == BoughtFilter.any;

  int get activeCount => [
    roomId,
    purpose,
    type,
    category,
    status,
    carId,
    if (inHome) true,
    if (warranty != WarrantyFilter.any) true,
    if (bought != BoughtFilter.any) true,
  ].whereType<Object>().length;

  ProductFilters copyWith({
    Object? roomId = _keep,
    Object? purpose = _keep,
    Object? type = _keep,
    Object? category = _keep,
    Object? status = _keep,
    Object? carId = _keep,
    bool? inHome,
    WarrantyFilter? warranty,
    BoughtFilter? bought,
  }) => ProductFilters(
    roomId: roomId == _keep ? this.roomId : roomId as String?,
    purpose: purpose == _keep ? this.purpose : purpose as Purpose?,
    type: type == _keep ? this.type : type as ItemType?,
    category: category == _keep ? this.category : category as Category?,
    status: status == _keep ? this.status : status as ItemStatus?,
    carId: carId == _keep ? this.carId : carId as String?,
    inHome: inHome ?? this.inHome,
    warranty: warranty ?? this.warranty,
    bought: bought ?? this.bought,
  );

  static const _keep = Object();

  bool matches(Item i, DateTime today) {
    if (roomId != null && !i.allocations.containsKey(roomId)) return false;
    if (purpose != null && i.purpose != purpose) return false;
    if (type != null && i.type != type) return false;
    if (category != null && i.category != category) return false;
    if (status != null && i.status != status) return false;
    if (carId != null && i.carId != carId) return false;
    if (inHome && !i.inInventory) return false;
    final end = i.warrantyEnd;
    switch (warranty) {
      case WarrantyFilter.any:
        break;
      case WarrantyFilter.none:
        if (end != null) return false;
      case WarrantyFilter.expired:
        if (end == null || !end.isBefore(today)) return false;
      case WarrantyFilter.ending:
        if (end == null ||
            end.isBefore(today) ||
            end.isAfter(Dates.addMonths(today, 3))) {
          return false;
        }
      case WarrantyFilter.active:
        if (end == null || end.isBefore(today)) return false;
    }
    // Same windows as the spending totals: the last 30 days is today and the
    // 29 before it; the last year ends today and starts a year ago + 1 day.
    final bought = i.purchaseDate;
    switch (this.bought) {
      case BoughtFilter.any:
        break;
      case BoughtFilter.days30:
        if (bought == null ||
            bought.isBefore(Dates.addDays(today, -29)) ||
            bought.isAfter(today)) {
          return false;
        }
      case BoughtFilter.year:
        if (bought == null ||
            bought.isBefore(Dates.addDays(Dates.addMonths(today, -12), 1)) ||
            bought.isAfter(today)) {
          return false;
        }
    }
    return true;
  }
}

class ProductsController extends GetxController {
  ProductsController(this.store);

  final VaultStore store;
  final query = ''.obs;
  final filters = const ProductFilters().obs;
  final sort = ProductSort.newest.obs;

  /// Quick chip under the search box: All, In my home, a category, Car.
  final quick = 'all'.obs;

  List<Item> apply(ProductFilters f) {
    final today = Dates.dateOnly(DateTime.now());
    final q = query.value;
    final list = store.items.where((i) {
      if (!f.matches(i, today)) return false;
      switch (quick.value) {
        case 'home':
          if (!i.inInventory) return false;
        case 'car':
          if (i.purpose != Purpose.car) return false;
        case 'all':
          break;
        default:
          if (i.category.name != quick.value) return false;
      }
      if (q.trim().isEmpty) return true;
      return SearchText.matches(q, [
        i.name,
        i.shop,
        i.category.label,
        i.receiptNumber,
        i.serial,
        i.model,
        for (final r in i.roomIds) store.room(r)?.name,
      ]);
    }).toList();
    switch (sort.value) {
      case ProductSort.newest:
        break;
      case ProductSort.oldest:
        list.setAll(0, list.reversed.toList());
      case ProductSort.priceHigh:
        list.sort((a, b) => b.value.compareTo(a.value));
      case ProductSort.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }
    return list;
  }

  List<Item> get visible => apply(filters.value);

  /// The most common categories, for quick chips.
  List<Category> get topCategories {
    final counts = <Category, int>{};
    for (final i in store.items) {
      counts[i.category] = (counts[i.category] ?? 0) + 1;
    }
    final sorted = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return sorted.where((c) => c != Category.car).take(3).toList();
  }

  /// Opens Products already filtered, e.g. "See 9 items for Golf".
  void showFor(ProductFilters f) {
    filters.value = f;
    quick.value = 'all';
  }
}
