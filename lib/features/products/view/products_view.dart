import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/item_rows.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../add/view/add_sheet.dart';
import '../controller/products_controller.dart';

/// 19 Products: all items, filter chips and sort.
class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return Constrained(
      child: Obx(() {
        final items = controller.visible;
        final total = controller.store.items.length;
        final f = controller.filters.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Products',
                      style: t.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Text(
                  items.length == total
                      ? Formatters.count(total, 'item')
                      : '${items.length} of $total',
                  style: t.titleMedium?.copyWith(
                    color: p.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SearchField(controller)),
                const SizedBox(width: 12),
                Badge(
                  isLabelVisible: f.activeCount > 0,
                  label: Text('${f.activeCount}'),
                  backgroundColor: p.primary,
                  child: SquareIconButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Filters',
                    onPressed: () => FiltersSheet.open(controller),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (key, label) in [
                    ('all', 'All'),
                    ('home', 'In my home'),
                    for (final c in controller.topCategories) (c.name, c.label),
                    ('car', 'Car'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoicePill(
                        label: label,
                        rounded: true,
                        selected: controller.quick.value == key,
                        onTap: () => controller.quick.value = key,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: () async {
                    final s = await Pickers.choose<ProductSort>(
                      context,
                      title: 'Sort',
                      values: ProductSort.values,
                      label: (s) => s.label,
                      selected: controller.sort.value,
                    );
                    if (s != null) controller.sort.value = s;
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          controller.sort.value.label,
                          style: TextStyle(
                            color: p.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          Icons.expand_more_rounded,
                          color: p.muted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!f.isEmpty)
                  TextButton(
                    onPressed: () =>
                        controller.filters.value = const ProductFilters(),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
            if (!controller.store.loaded.value)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (total == 0)
              EmptyState(
                icon: Icons.view_in_ar_outlined,
                title: 'Nothing here yet',
                message:
                    'Items appear here once you save a receipt or add something '
                    'you already own.',
                action: VaultButton(
                  label: 'Add a receipt',
                  expand: false,
                  onPressed: AddSheet.open,
                ),
              )
            else if (items.isEmpty)
              const EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No items match',
                message: 'Try fewer filters or a different word.',
              )
            else
              ListCard(
                indent: 82,
                children: [
                  for (final i in items.take(300))
                    ItemRow(
                      i,
                      showViewReceipt: true,
                      highlight: controller.query.value,
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }
}

/// 20 Filters sheet: room, purpose, type, warranty, date bought.
/// Owns its text controller. GetX deletes [ProductsController] when the
/// shell route is disposed, which can happen a frame before this field is
/// unmounted (sign-out, account deletion); a controller-owned
/// TextEditingController would then be used after dispose.
class _SearchField extends StatefulWidget {
  const _SearchField(this.products);

  final ProductsController products;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _text = TextEditingController(text: widget.products.query.value);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      onChanged: (v) => widget.products.query.value = v,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 17),
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: Icon(Icons.search_rounded, color: context.palette.muted),
      ),
    );
  }
}

class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key, required this.controller});

  final ProductsController controller;

  static Future<void> open(ProductsController c) =>
      SheetFrame.show<void>(FiltersSheet(controller: c));

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  late ProductFilters f = widget.controller.filters.value;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final store = c.store;
    final count = c.apply(f).length;
    Widget group<T>(
      String title,
      List<T?> values,
      T? selected,
      String Function(T?) label,
      void Function(T?) onSelected,
    ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Text(title, style: context.textStyles.titleMedium),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in values)
              ChoicePill(
                label: label(v),
                selected: v == selected,
                onTap: () => setState(() => onSelected(v)),
              ),
          ],
        ),
      ],
    );

    return SheetFrame(
      title: 'Filter products',
      trailing: LinkButton(
        label: 'Reset',
        onPressed: () => setState(() => f = const ProductFilters()),
      ),
      actions: [
        VaultButton.secondary(label: 'Cancel', onPressed: Get.back),
        VaultButton(
          label: 'Show ${Formatters.count(count, 'item')}',
          onPressed: () {
            c.filters.value = f;
            Get.back<void>();
          },
        ),
      ],
      children: [
        if (store.rooms.isNotEmpty)
          group<String>(
            'Room',
            [null, for (final r in store.rooms) r.id],
            f.roomId,
            (id) => id == null ? 'Any' : store.room(id)!.name,
            (v) => f = f.copyWith(roomId: v),
          ),
        group<Purpose>(
          'Purpose',
          [null, ...Purpose.values],
          f.purpose,
          (v) => v?.label ?? 'Any',
          (v) => f = f.copyWith(purpose: v),
        ),
        group<ItemType>(
          'Type',
          [null, ...ItemType.values],
          f.type,
          (v) => v?.label ?? 'Any',
          (v) => f = f.copyWith(type: v),
        ),
        group<WarrantyFilter>(
          'Warranty',
          WarrantyFilter.values,
          f.warranty,
          (v) => v!.label,
          (v) => f = f.copyWith(warranty: v),
        ),
        group<BoughtFilter>(
          'Bought',
          BoughtFilter.values,
          f.bought,
          (v) => v!.label,
          (v) => f = f.copyWith(bought: v),
        ),
        group<Category>(
          'Category',
          [null, ...Category.values],
          f.category,
          (v) => v?.label ?? 'Any',
          (v) => f = f.copyWith(category: v),
        ),
        group<ItemStatus>(
          'Status',
          [null, ...ItemStatus.values],
          f.status,
          (v) => v?.label ?? 'Any',
          (v) => f = f.copyWith(status: v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
