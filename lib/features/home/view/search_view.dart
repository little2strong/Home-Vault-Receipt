import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/item.dart';
import '../../../core/models/receipt.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/search.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/item_rows.dart';
import '../../../core/widgets/vault_ui.dart';

enum SearchScope { all, items, receipts, rooms }

class VaultSearchController extends GetxController {
  VaultSearchController(this.store);

  final VaultStore store;
  final text = TextEditingController();
  final query = ''.obs;
  final scope = SearchScope.all.obs;

  @override
  void onInit() {
    super.onInit();
    debounce(query, (_) {}, time: const Duration(milliseconds: 120));
  }

  /// Item name, shop, category, room and receipt number.
  List<Item> get items {
    final q = query.value;
    if (q.trim().isEmpty) return [];
    return store.items
        .where(
          (i) => SearchText.matches(q, [
            i.name,
            i.shop,
            i.category.label,
            i.receiptNumber,
            i.serial,
            i.model,
            i.purpose.label,
            for (final r in i.roomIds) store.room(r)?.name,
          ]),
        )
        .toList();
  }

  List<Receipt> get receipts {
    final q = query.value;
    if (q.trim().isEmpty) return [];
    return store.receipts
        .where(
          (r) => SearchText.matches(q, [
            r.shop,
            r.number,
            r.number.replaceAll('-', ''),
            r.orderNumber,
            for (final i in store.itemsOnReceipt(r.id)) i.name,
          ]),
        )
        .toList();
  }

  List<Room> get rooms {
    final q = query.value;
    if (q.trim().isEmpty) return [];
    return store.rooms.where((r) => SearchText.matches(q, [r.name])).toList();
  }

  @override
  void onClose() {
    text.dispose();
    super.onClose();
  }
}

/// 07 Search results across items, shops, rooms and receipt numbers.
class SearchView extends GetView<VaultSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Constrained(
          child: Column(
            children: [
              const OfflineBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.pagePadding,
                  AppSizes.md,
                  AppSizes.pagePadding,
                  0,
                ),
                child: Row(
                  children: [
                    const SquareIconButton.back(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller.text,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (v) => controller.query.value = v,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Search items, shops, rooms',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: p.muted,
                          ),
                          suffixIcon: Obx(
                            () => controller.query.value.isEmpty
                                ? const SizedBox.shrink()
                                : IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      controller.text.clear();
                                      controller.query.value = '';
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  final q = controller.query.value;
                  final items = controller.items;
                  final receipts = controller.receipts;
                  final rooms = controller.rooms;
                  final scope = controller.scope.value;
                  final total = items.length + receipts.length + rooms.length;
                  bool show(SearchScope s) =>
                      scope == SearchScope.all || scope == s;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.pagePadding,
                      AppSizes.md,
                      AppSizes.pagePadding,
                      AppSizes.xl,
                    ),
                    children: [
                      if (q.trim().isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final (s, label, n) in [
                                (SearchScope.all, 'All', total),
                                (SearchScope.items, 'Items', items.length),
                                (
                                  SearchScope.receipts,
                                  'Receipts',
                                  receipts.length,
                                ),
                                (SearchScope.rooms, 'Rooms', rooms.length),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoicePill(
                                    label: label,
                                    count: n,
                                    rounded: true,
                                    selected: scope == s,
                                    onTap: () => controller.scope.value = s,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (q.trim().isEmpty)
                        const EmptyState(
                          icon: Icons.search_rounded,
                          title: 'Find anything you own',
                          message:
                              'Search by item, shop, room or a receipt number '
                              'such as HV-000123.',
                        )
                      else if (total == 0)
                        EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nothing matches "$q"',
                          message: 'Try a shop name, a room or part of a word.',
                        ),
                      if (show(SearchScope.items) && items.isNotEmpty) ...[
                        const SectionLabel('Items'),
                        ListCard(
                          indent: 82,
                          children: [
                            for (final i in items.take(50))
                              ItemRow(i, highlight: q),
                          ],
                        ),
                      ],
                      if (show(SearchScope.receipts) &&
                          receipts.isNotEmpty) ...[
                        const SectionLabel('Receipts'),
                        ListCard(
                          indent: 82,
                          children: [
                            for (final r in receipts.take(30))
                              ReceiptRow(r, highlight: q),
                          ],
                        ),
                      ],
                      if (show(SearchScope.rooms) && rooms.isNotEmpty) ...[
                        const SectionLabel('Rooms'),
                        ListCard(
                          indent: 82,
                          children: [
                            for (final r in rooms)
                              RowTile(
                                leading: IconTile(r.type.icon, size: 52),
                                title: r.name,
                                highlight: q,
                                subtitle: Formatters.count(
                                  controller.store.itemCountInRoom(r.id),
                                  'item',
                                ),
                                chevron: true,
                                onTap: () => Get.toNamed(Routes.room(r.id)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
