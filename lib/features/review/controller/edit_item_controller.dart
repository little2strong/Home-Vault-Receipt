import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/product_category.dart';
import '../../../core/models/receipt_item.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/pickers.dart';

class ItemEditArgs {
  const ItemEditArgs({this.item, this.currency = 'GBP', this.canRemove = true});

  /// Null when adding a missing product.
  final ReceiptItem? item;
  final String currency;
  final bool canRemove;

  /// Used as the controller tag, so it must be unique per open.
  @override
  String toString() =>
      'edit-item-${item?.id ?? 'new'}-${identityHashCode(this)}';
}

class ItemEditResult {
  const ItemEditResult.saved(ReceiptItem this.item) : removed = false;
  const ItemEditResult.removed() : item = null, removed = true;

  final ReceiptItem? item;
  final bool removed;
}

/// 26 · Edit line item. Returns an [ItemEditResult] to whoever opened it
/// (review, manual entry, receipt detail).
class EditItemController extends GetxController {
  EditItemController({required this.args})
    : nameController = TextEditingController(text: args.item?.name),
      sourceController = TextEditingController(
        text: args.item?.sourceDescription,
      ),
      quantityController = TextEditingController(
        text: '${args.item?.quantity ?? 1}',
      ),
      totalController = TextEditingController(
        text: args.item == null ? '' : Money.toInput(args.item!.lineTotal),
      ),
      category = (args.item?.category ?? ProductCategory.other).obs;

  final ItemEditArgs args;
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController;
  final TextEditingController sourceController;
  final TextEditingController quantityController;
  final TextEditingController totalController;
  final Rx<ProductCategory> category;

  bool get isNew => args.item == null;

  String get currencySymbol => Money.symbolFor(args.currency);

  Future<void> pickCategory(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Category',
      options: [for (final c in ProductCategory.values) c.label],
      selected: category.value.index,
    );
    if (i != null) category.value = ProductCategory.values[i];
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final source = sourceController.text.trim();
    final item = ReceiptItem(
      id: args.item?.id ?? Ids.next('item'),
      name: nameController.text.trim(),
      sourceDescription: source.isEmpty ? null : source,
      quantity: int.parse(quantityController.text.trim()),
      lineTotal: Money.parse(totalController.text)!,
      category: category.value,
    );
    Get.back(result: ItemEditResult.saved(item));
  }

  void remove() => Get.back(result: const ItemEditResult.removed());

  @override
  void onClose() {
    nameController.dispose();
    sourceController.dispose();
    quantityController.dispose();
    totalController.dispose();
    super.onClose();
  }
}
