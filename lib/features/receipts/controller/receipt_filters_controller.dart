import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/models/product_category.dart';
import '../../../core/models/receipt_filter.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/pickers.dart';
import 'receipts_controller.dart';

/// 12 · Receipt filters. Edits a copy of the list's filter and previews the
/// result count before applying.
class ReceiptFiltersController extends GetxController {
  ReceiptFiltersController({required this._receipts, required this._list})
    : draft = _list.filter.value.obs;

  final ReceiptRepository _receipts;
  final ReceiptsController _list;
  final Rx<ReceiptFilter> draft;

  int get matchCount => _receipts.search(draft.value).length;

  List<String> get retailers {
    final names = {for (final r in _receipts.saved) r.retailer};
    return names.toList()..sort();
  }

  String get categoryLabel => draft.value.category?.label ?? AppStrings.any;

  String get datesLabel {
    final f = draft.value;
    if (f.from == null || f.to == null) return 'Any date';
    return Formatters.dateRange(f.from!, f.to!);
  }

  String get currencyLabel => draft.value.currency ?? AppStrings.any;

  String get retailerLabel => draft.value.retailer ?? 'Any retailer';

  Future<void> pickCategory(BuildContext context) async {
    final options = [
      AppStrings.any,
      for (final c in ProductCategory.values) c.label,
    ];
    final current = draft.value.category;
    final i = await showOptionSheet(
      context,
      title: 'Category',
      options: options,
      selected: current == null ? 0 : current.index + 1,
    );
    if (i == null) return;
    draft.value = i == 0
        ? draft.value.copyWith(clearCategory: true)
        : draft.value.copyWith(category: ProductCategory.values[i - 1]);
  }

  Future<void> pickDates(BuildContext context) async {
    final today = _receipts.today;
    final current = draft.value;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: current.from == null || current.to == null
          ? null
          : DateTimeRange(start: current.from!, end: current.to!),
      helpText: 'Purchase dates',
    );
    if (range != null) {
      draft.value = draft.value.copyWith(from: range.start, to: range.end);
    }
  }

  void clearDates() => draft.value = draft.value.copyWith(clearDates: true);

  Future<void> pickCurrency(BuildContext context) async {
    final options = [AppStrings.any, ...Money.currencies];
    final current = draft.value.currency;
    final i = await showOptionSheet(
      context,
      title: 'Currency',
      options: options,
      selected: current == null ? 0 : options.indexOf(current),
    );
    if (i == null) return;
    draft.value = i == 0
        ? draft.value.copyWith(clearCurrency: true)
        : draft.value.copyWith(currency: options[i]);
  }

  Future<void> pickRetailer(BuildContext context) async {
    final options = ['Any retailer', ...retailers];
    final current = draft.value.retailer;
    final i = await showOptionSheet(
      context,
      title: 'Retailer',
      options: options,
      selected: current == null ? 0 : options.indexOf(current),
    );
    if (i == null) return;
    draft.value = i == 0
        ? draft.value.copyWith(clearRetailer: true)
        : draft.value.copyWith(retailer: options[i]);
  }

  Future<void> pickDeadline(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Return deadline',
      options: [for (final d in DeadlineFilter.values) d.label],
      selected: draft.value.deadline.index,
    );
    if (i != null) {
      draft.value = draft.value.copyWith(deadline: DeadlineFilter.values[i]);
    }
  }

  void reset() => draft.value = draft.value.cleared();

  void apply() {
    _list.applyRefinements(draft.value);
    Get.back();
  }
}
