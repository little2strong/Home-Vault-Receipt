import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/item.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/search.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/item_rows.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../products/controller/products_controller.dart';
import '../../start/controller/start_controllers.dart';
import 'web_shell.dart';

// --------------------------------------------------------- W1 Sign in

/// W1 Website sign in — the same account as the app.
class WebSignInView extends GetView<SignInController> {
  const WebSignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wide = MediaQuery.sizeOf(context).width > 820;
    final form = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            if (!wide) ...[const BrandRow(), const SizedBox(height: 32)],
            Text('Sign in', style: context.textStyles.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Use the same account as the app.',
              style: TextStyle(color: p.muted),
            ),
            const SizedBox(height: 20),
            Obx(
              () => VaultButton.dark(
                label: 'Continue with Apple',
                icon: Icons.apple,
                loading: controller.busy.value == 'apple',
                onPressed: controller.apple,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => VaultButton.secondary(
                label: 'Continue with Google',
                loading: controller.busy.value == 'google',
                onPressed: controller.google,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: p.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: TextStyle(color: p.muted)),
                ),
                Expanded(child: Divider(color: p.outline)),
              ],
            ),
            LabeledField(
              label: 'Email address',
              controller: controller.email,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 12),
            Obx(
              () => VaultButton.secondary(
                label: 'Email me a sign-in link',
                loading: controller.busy.value == 'email',
                onPressed: controller.emailLink,
              ),
            ),
            Obx(
              () => controller.error.value == null
                  ? const SizedBox(height: 12)
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InfoNote(controller.error.value!, warning: true),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              'New here? Get the app to start saving receipts.',
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
            LinkButton(
              label: 'Privacy policy',
              onPressed: () => Get.toNamed(Routes.privacy),
            ),
          ],
        ),
      ),
    );
    if (!wide) {
      return Scaffold(
        backgroundColor: p.background,
        body: SafeArea(child: form),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: p.hero,
              padding: const EdgeInsets.all(64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandRow(light: true),
                  const Spacer(),
                  Text(
                    'Your home inventory, even if your phone is gone',
                    style: context.textStyles.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in from any computer to see your receipts and download '
                    'your list for an insurer.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(color: p.background, child: form),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- W2 Dashboard

/// W2 Website dashboard: totals, warranties, quick downloads.
class WebDashboardView extends StatelessWidget {
  const WebDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final p = context.palette;
    final t = context.textStyles;
    return WebScaffold(
      current: Routes.webDashboard,
      child: Obx(() {
        final profile = store.profile.value;
        final main = profile?.mainCurrency ?? 'GBP';
        final s = store.stats.value;
        final inv = store.inventory;
        final today = DateTime.now();
        final ending = store.warrantiesWith(WarrantyStatus.expiring);
        final wide = MediaQuery.sizeOf(context).width > 820;
        final stats = [
          StatTile(
            label: 'Last 30 days',
            value: money(s.last30Days[main] ?? 0, main),
            caption: Formatters.count(s.receipts30, 'receipt'),
          ),
          StatTile(
            label: 'Last year',
            value: money(s.last365Days[main] ?? 0, main),
            caption: Formatters.count(s.receipts365, 'receipt'),
          ),
          StatTile(
            label: 'Lifetime',
            value: money(s.lifetime[main] ?? 0, main),
            caption: s.firstPurchase == null
                ? null
                : 'Since ${Formatters.months[s.firstPurchase!.month - 1].substring(0, 3)} ${s.firstPurchase!.year}',
          ),
          HeroCard(
            onTap: () => Get.offAllNamed(Routes.webInventory),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Home inventory',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                FittedBox(
                  child: Text(
                    moneyTotals(store.inventoryTotals(), main: main),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${Formatters.count(inv.length, 'item')} · ${Formatters.count(store.rooms.length, 'room')}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back${profile?.firstName.isNotEmpty ?? false ? ', ${profile!.firstName}' : ''}',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: stats[i]),
                  ],
                ],
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final s in stats) SizedBox(width: 260, child: s),
                ],
              ),
            const SizedBox(height: 16),
            Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: wide ? 1 : 0,
                  child: VaultCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Warranties ending soon', style: t.titleMedium),
                        const SizedBox(height: 8),
                        if (ending.isEmpty)
                          Text(
                            'Nothing ends in the next 3 months.',
                            style: TextStyle(color: p.muted),
                          ),
                        for (final w in ending)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: w.itemName ?? 'Item',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              ' · ends ${Formatters.medium(w.endDate)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Pill(
                                  Formatters.daysRemaining(w.daysLeft(today)),
                                  tone: PillTone.amber,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                Flexible(
                  flex: wide ? 1 : 0,
                  child: VaultCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick downloads', style: t.titleMedium),
                        const SizedBox(height: 12),
                        RowTile(
                          leading: const IconTile(
                            Icons.meeting_room_outlined,
                            size: 40,
                          ),
                          title: 'Home inventory',
                          subtitle: 'PDF with photos, by room',
                          onTap: () => Get.offAllNamed(Routes.webDownloads),
                        ),
                        RowTile(
                          leading: const IconTile(
                            Icons.view_in_ar_outlined,
                            size: 40,
                          ),
                          title: 'Itemised product list',
                          subtitle: 'CSV or PDF',
                          onTap: () => Get.offAllNamed(Routes.webDownloads),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            VaultCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Recent purchases', style: t.titleMedium),
                  const SizedBox(height: 12),
                  _ItemsTable(
                    items: store.items.take(6).toList(),
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items, this.compact = false});

  final List<Item> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final p = context.palette;
    final wide = MediaQuery.sizeOf(context).width > 820;
    final today = DateTime.now();
    if (items.isEmpty) {
      return Text(
        'No items yet. Save receipts in the app to see them here.',
        style: TextStyle(color: p.muted),
      );
    }
    Widget warranty(Item i) {
      final w = store.warrantyFor(i.id);
      if (w == null) return Text('None', style: TextStyle(color: p.muted));
      return switch (w.statusOn(today)) {
        WarrantyStatus.active => const Pill('Active', tone: PillTone.green),
        WarrantyStatus.expiring => Pill(
          '${w.daysLeft(today)} days left',
          tone: PillTone.amber,
        ),
        WarrantyStatus.expired => const Pill('Expired', tone: PillTone.grey),
      };
    }

    if (!wide) {
      return ListCard(
        indent: 82,
        children: [for (final i in items) _WebItemRow(item: i)],
      );
    }
    return WebTable(
      columns: compact
          ? const ['Item', 'Shop', 'Date', 'Room', 'Price']
          : const [
              'Item',
              'Receipt',
              'Bought',
              'Room / purpose',
              'Warranty',
              'Price',
            ],
      flex: compact ? const [3, 2, 2, 2, 1] : const [3, 2, 2, 3, 2, 2],
      alignEnd: {compact ? 4 : 5},
      onTap: (r) => Get.toNamed(Routes.webItem(items[r].id)),
      rows: [
        for (final i in items)
          [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i.displayName,
                  style: TextStyle(
                    color: p.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact && i.shop != null)
                  Text(i.shop!, style: TextStyle(color: p.muted, fontSize: 13)),
              ],
            ),
            if (compact)
              Text(i.shop ?? '—')
            else
              Text(
                i.receiptNumber ?? 'No receipt',
                style: TextStyle(
                  color: i.receiptNumber == null ? p.muted : p.primary,
                ),
              ),
            Text(
              i.purchaseDate == null
                  ? (i.yearBought == null ? '—' : 'About ${i.yearBought}')
                  : Formatters.medium(i.purchaseDate!),
            ),
            compact
                ? Text(store.roomLabel(i))
                : Pill(store.roomLabel(i), tone: PillTone.green),
            if (!compact) warranty(i),
            Text(
              money(
                i.lineTotalMinor == null && i.unitPriceMinor == null
                    ? null
                    : i.value,
                i.currency,
                estimate: i.estimated,
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
      ],
    );
  }
}

class _WebItemRow extends StatelessWidget {
  const _WebItemRow({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) => RowTile(
    leading: ItemLeading(item),
    title: item.displayName,
    subtitle: [
      item.shop,
      Get.find<VaultStore>().roomLabel(item),
    ].whereType<String>().join(' · '),
    trailingText: money(item.value, item.currency, estimate: item.estimated),
    onTap: () => Get.toNamed(Routes.webItem(item.id)),
  );
}

// -------------------------------------------------------- W3 Products

class WebProductsController extends GetxController {
  WebProductsController(this.store);

  final VaultStore store;
  final query = ''.obs;
  final filters = const ProductFilters(bought: BoughtFilter.any).obs;
  final page = 0.obs;
  static const pageSize = 25;

  List<Item> get filtered {
    final today = DateTime.now();
    final q = query.value;
    return store.items.where((i) {
      if (!filters.value.matches(i, today)) return false;
      if (q.trim().isEmpty) return true;
      return SearchText.matches(q, [
        i.name,
        i.shop,
        i.receiptNumber,
        i.category.label,
        for (final r in i.roomIds) store.room(r)?.name,
      ]);
    }).toList();
  }
}

/// W3 Website products: a searchable table of items.
class WebProductsView extends GetView<WebProductsController> {
  const WebProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final store = controller.store;
    return WebScaffold(
      current: Routes.webProducts,
      child: Obx(() {
        final all = controller.filtered;
        final pages = (all.length / WebProductsController.pageSize).ceil();
        final page = controller.page.value.clamp(0, pages == 0 ? 0 : pages - 1);
        final start = page * WebProductsController.pageSize;
        final shown = all
            .skip(start)
            .take(WebProductsController.pageSize)
            .toList();
        final f = controller.filters.value;
        Widget drop<T>(
          String hint,
          T? value,
          List<T?> values,
          String Function(T?) label,
          void Function(T?) on,
        ) => DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T?>(
                value: value,
                hint: Text(hint),
                items: [
                  for (final v in values)
                    DropdownMenuItem(value: v, child: Text(label(v))),
                ],
                onChanged: (v) {
                  on(v);
                  controller.page.value = 0;
                },
              ),
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: context.textStyles.headlineMedium,
                      ),
                      Text(
                        '${Formatters.count(store.items.length, 'item')} from ${Formatters.count(store.receipts.length, 'receipt')}',
                        style: TextStyle(color: p.muted),
                      ),
                    ],
                  ),
                ),
                VaultButton(
                  label: 'Download this list',
                  icon: Icons.download_rounded,
                  expand: false,
                  onPressed: () => Get.offAllNamed(Routes.webDownloads),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    onChanged: (v) {
                      controller.query.value = v;
                      controller.page.value = 0;
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search items, shops, receipt numbers',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                drop<String>(
                  'All rooms',
                  f.roomId,
                  [null, for (final r in store.rooms) r.id],
                  (id) => id == null ? 'All rooms' : store.room(id)!.name,
                  (v) => controller.filters.value = f.copyWith(roomId: v),
                ),
                drop<Purpose>(
                  'All purposes',
                  f.purpose,
                  [null, ...Purpose.values],
                  (v) => v?.label ?? 'All purposes',
                  (v) => controller.filters.value = f.copyWith(purpose: v),
                ),
                drop<WarrantyFilter>(
                  'Any warranty',
                  f.warranty,
                  WarrantyFilter.values,
                  (v) => v == WarrantyFilter.any ? 'Any warranty' : v!.label,
                  (v) => controller.filters.value = f.copyWith(warranty: v),
                ),
                drop<BoughtFilter>(
                  'Any time',
                  f.bought,
                  BoughtFilter.values,
                  (v) => v!.label,
                  (v) => controller.filters.value = f.copyWith(bought: v),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ItemsTable(items: shown),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  all.isEmpty
                      ? 'No items match'
                      : 'Showing ${start + 1}–${start + shown.length} of ${all.length}',
                  style: TextStyle(color: p.muted),
                ),
                const Spacer(),
                if (page > 0)
                  LinkButton(
                    label: 'Previous page',
                    onPressed: () => controller.page.value = page - 1,
                  ),
                if (page < pages - 1)
                  LinkButton(
                    label: 'Next page',
                    onPressed: () => controller.page.value = page + 1,
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

// ----------------------------------------------------- W4 Item detail

/// W4 Website item detail: item, photos and View receipt.
class WebItemView extends StatefulWidget {
  const WebItemView({super.key});

  @override
  State<WebItemView> createState() => _WebItemViewState();
}

class _WebItemViewState extends State<WebItemView> {
  final store = Get.find<VaultStore>();
  final repo = Get.find<VaultRepository>();
  late final String id = Get.parameters['id'] ?? '';
  List<ItemPhoto> photos = [];
  int selected = 0;
  StreamSubscription<List<ItemPhoto>>? sub;

  @override
  void initState() {
    super.initState();
    sub = repo
        .photos(id)
        .listen((p) => setState(() => photos = p), onError: (_) {});
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  Future<void> _sheet(Item item) async {
    final exportId = await repo.requestExport(
      kind: ExportKind.products,
      format: ExportFormat.pdf,
    );
    Toast.show('Building the item list — it appears in Downloads.');
    await Get.offAllNamed(Routes.webDownloads, arguments: exportId);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    final wide = MediaQuery.sizeOf(context).width > 820;
    return WebScaffold(
      current: Routes.webProducts,
      child: Obx(() {
        final item = store.item(id);
        if (item == null) {
          return const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Item not found',
            message: 'It may have been deleted in the app.',
          );
        }
        final w = store.warrantyFor(item.id);
        final today = DateTime.now();
        final gallery = Column(
          children: [
            AspectRatio(
              aspectRatio: 1.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photos.isEmpty
                    ? Container(
                        color: const Color(0xFF3E4744),
                        child: Icon(
                          item.category.icon,
                          color: Colors.white54,
                          size: 64,
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          PrivateImage(
                            path: photos[selected].path,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              color: Colors.black54,
                              child: Text(
                                photos[selected].source == PhotoSource.camera
                                    ? 'Taken in Home Vault · ${Formatters.medium(photos[selected].deviceTakenAt ?? today)}'
                                    : 'Added from gallery',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < photos.length && i < 5; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: i == selected ? p.primary : p.outline,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PrivateImage(
                            path: photos[i].thumbPath ?? photos[i].path,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.category.label} · ${item.type.label} · ${item.purpose.label}',
              style: TextStyle(color: p.muted, fontWeight: FontWeight.w700),
            ),
            Text(
              item.displayName,
              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              money(item.value, item.currency, estimate: item.estimated),
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ListCard(
              children: [
                DetailRow(
                  'Bought',
                  [
                    if (item.purchaseDate != null)
                      Formatters.medium(item.purchaseDate!),
                    ?item.shop,
                  ].join(' · '),
                ),
                DetailRow(
                  'Receipt',
                  item.receiptNumber == null
                      ? 'No receipt'
                      : '${item.receiptNumber} · ${Formatters.count(store.itemsOnReceipt(item.receiptId!).length, 'item')}',
                  muted: item.receiptNumber == null,
                ),
                DetailRow('Room', store.roomLabel(item)),
                DetailRow(
                  'Warranty',
                  w == null
                      ? 'None'
                      : '${w.statusOn(today).label} · ends ${Formatters.medium(w.endDate)}',
                  valueColor: w == null ? null : p.primary,
                  muted: w == null,
                ),
                if (item.serial != null)
                  DetailRow('Serial number', item.serial!),
                DetailRow(
                  'Evidence',
                  photos.isEmpty
                      ? 'No photos'
                      : '${Formatters.count(photos.length, 'photo')} · fingerprints recorded',
                  muted: photos.isEmpty,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (item.receiptId != null)
                  VaultButton(
                    label: 'View original receipt',
                    expand: false,
                    onPressed: () => Get.toNamed(
                      Routes.original(item.receiptId!),
                      arguments: {'itemId': item.id},
                    ),
                  ),
                VaultButton.secondary(
                  label: 'Download item list',
                  expand: false,
                  onPressed: () => _sheet(item),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Originals and photos load only when you open them. Editing is done in the app.',
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinkButton(
              label: '‹ Products',
              underline: false,
              onPressed: () => Get.offAllNamed(Routes.webProducts),
            ),
            const SizedBox(height: 10),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: gallery),
                  const SizedBox(width: 24),
                  Expanded(child: details),
                ],
              )
            else ...[
              gallery,
              const SizedBox(height: 20),
              details,
            ],
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------- W5 Home inventory

/// W5 Website home inventory: items by room, ready for insurers.
class WebInventoryView extends StatelessWidget {
  const WebInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final selected = RxnString();
    final p = context.palette;
    return WebScaffold(
      current: Routes.webInventory,
      child: Obx(() {
        final rooms = store.rooms;
        final main = store.profile.value?.mainCurrency ?? 'GBP';
        final roomId = selected.value ?? rooms.firstOrNull?.id;
        final inv = store.inventory;
        final estimates = inv.where((i) => i.estimated).length;
        final items = roomId == null ? <Item>[] : store.itemsInRoom(roomId);
        final wide = MediaQuery.sizeOf(context).width > 820;
        final list = Column(
          children: [
            for (final r in rooms)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: r.id == roomId ? p.surface : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: r.id == roomId ? p.outline : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      r.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: Text('${store.itemCountInRoom(r.id)}'),
                    onTap: () => selected.value = r.id,
                  ),
                ),
              ),
          ],
        );
        final table = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    roomId == null ? 'No rooms yet' : store.room(roomId)!.name,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (roomId != null)
                  Text(
                    moneyTotals(store.inventoryTotals(roomId), main: main),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'No items in this room yet.',
                style: TextStyle(color: p.muted),
              )
            else
              WebTable(
                columns: const ['Item', 'Evidence', 'Bought', 'Price'],
                flex: const [4, 3, 2, 2],
                alignEnd: const {3},
                onTap: (r) => Get.toNamed(Routes.webItem(items[r].id)),
                rows: [
                  for (final i in items)
                    [
                      Row(
                        children: [
                          ItemLeading(i, size: 40),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      i.name,
                                      style: TextStyle(
                                        color: p.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (i.highValue)
                                      const Pill(
                                        'High value',
                                        tone: PillTone.amber,
                                      ),
                                  ],
                                ),
                                if (i.isSplit)
                                  Text(
                                    '${i.allocations[roomId]} of ${i.quantity} · other in ${i.allocations.keys.where((k) => k != roomId).map((k) => store.room(k)?.name ?? 'another room').join(', ')}',
                                    style: TextStyle(
                                      color: p.muted,
                                      fontSize: 13,
                                    ),
                                  )
                                else if (i.serial != null)
                                  Text(
                                    'Serial ${i.serial}',
                                    style: TextStyle(
                                      color: p.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        [
                          i.receiptNumber == null
                              ? 'No receipt'
                              : 'Receipt ${i.receiptNumber}',
                          if (i.photoCount > 0)
                            Formatters.count(i.photoCount, 'photo')
                          else
                            'no photo',
                        ].join(' · '),
                        style: TextStyle(
                          color: i.receiptNumber == null && i.photoCount == 0
                              ? p.warningInk
                              : null,
                          fontWeight:
                              i.receiptNumber == null && i.photoCount == 0
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                      Text(
                        i.purchaseDate == null
                            ? (i.yearBought == null
                                  ? '—'
                                  : 'About ${i.yearBought}')
                            : Formatters.medium(i.purchaseDate!),
                      ),
                      Text(
                        money(
                          i.valueInRoom(roomId!),
                          i.currency,
                          estimate: i.estimated,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                ],
              ),
            const SizedBox(height: 10),
            Text(
              'Prices are what you paid, not replacement value. Your insurer decides what is covered.',
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home inventory',
                        style: context.textStyles.headlineMedium,
                      ),
                      Text(
                        '${Formatters.count(inv.length, 'item')} · ${Formatters.count(rooms.length, 'room')} · '
                        '${moneyTotals(store.inventoryTotals(), main: main)} paid · '
                        '${Formatters.count(estimates, 'estimate')} without receipts',
                        style: TextStyle(color: p.muted),
                      ),
                    ],
                  ),
                ),
                VaultButton(
                  label: 'Download for insurer',
                  icon: Icons.download_rounded,
                  expand: false,
                  onPressed: () => Get.offAllNamed(
                    Routes.webDownloads,
                    arguments: ExportKind.inventory,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 220, child: list),
                  const SizedBox(width: 20),
                  Expanded(child: table),
                ],
              )
            else ...[
              list,
              const SizedBox(height: 16),
              table,
            ],
          ],
        );
      }),
    );
  }
}

// ------------------------------------------------------- W6 Downloads

/// W6 Website downloads: request and download PDF, CSV, ZIP.
class WebDownloadsView extends StatelessWidget {
  const WebDownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final repo = Get.find<VaultRepository>();
    final p = context.palette;
    final formats = {
      ExportKind.inventory: ExportFormat.pdf.obs,
      ExportKind.products: ExportFormat.csv.obs,
      ExportKind.archive: ExportFormat.zip.obs,
    };
    final busy = Rxn<ExportKind>();
    Future<void> create(ExportKind kind, [ExportFormat? format]) async {
      busy.value = kind;
      try {
        await repo.requestExport(
          kind: kind,
          format: format ?? formats[kind]!.value,
        );
        Toast.show("We're building your list. It appears below in a moment.");
      } catch (_) {
        Toast.show("The download couldn't start. Try again.");
      } finally {
        busy.value = null;
      }
    }

    return WebScaffold(
      current: Routes.webDownloads,
      child: Obx(() {
        final now = DateTime.now();
        final wide = MediaQuery.sizeOf(context).width > 820;
        final cards = [
          for (final (kind, icon, desc, options) in [
            (
              ExportKind.inventory,
              Icons.meeting_room_outlined,
              'Items in your home by room, with photos, serial numbers and receipt numbers.',
              [ExportFormat.pdf, ExportFormat.csv],
            ),
            (
              ExportKind.products,
              Icons.view_in_ar_outlined,
              "Everything you've bought. Filter by date, purpose or room first.",
              [ExportFormat.pdf, ExportFormat.csv],
            ),
            (
              ExportKind.archive,
              Icons.folder_zip_outlined,
              'All your data plus original receipts and photos, in one ZIP file.',
              [ExportFormat.zip],
            ),
          ])
            VaultCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(icon, size: 44),
                  const SizedBox(height: 12),
                  Text(kind.label, style: context.textStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: p.muted)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in options)
                        ChoicePill(
                          label: f.label,
                          selected: formats[kind]!.value == f,
                          onTap: () => formats[kind]!.value = f,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  VaultButton(
                    label: 'Create',
                    loading: busy.value == kind,
                    onPressed: () => create(kind),
                  ),
                ],
              ),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Downloads', style: context.textStyles.headlineMedium),
            Text(
              "Request a list. It's built privately and the link works for 24 hours.",
              style: TextStyle(color: p.muted),
            ),
            const SizedBox(height: 20),
            if (wide)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 14),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              )
            else
              for (final c in cards)
                Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
            const SizedBox(height: 20),
            if (store.exports.isNotEmpty)
              WebTable(
                columns: const ['Requested', 'List', 'Size', 'Status', ''],
                flex: const [2, 3, 1, 2, 2],
                alignEnd: const {4},
                rows: [
                  for (final job in store.exports)
                    [
                      Text(
                        job.requestedAt == null
                            ? '—'
                            : Formatters.expiry(
                                job.requestedAt!,
                                now,
                              ).replaceFirst(' at', ','),
                      ),
                      Text('${job.kind.label} · ${job.format.label}'),
                      Text(
                        job.sizeBytes == null
                            ? '—'
                            : Formatters.fileSize(job.sizeBytes!),
                      ),
                      switch (job) {
                        _ when job.isReady(now) => Pill(
                          'Ready · ${job.expiresAt!.difference(now).inHours} h left',
                          tone: PillTone.green,
                        ),
                        _ when job.status == ExportStatus.failed => const Pill(
                          'Failed',
                          tone: PillTone.red,
                        ),
                        _ when job.isExpired(now) => const Pill(
                          'Expired',
                          tone: PillTone.grey,
                        ),
                        _ => const Pill('Building…', tone: PillTone.amber),
                      },
                      if (job.isReady(now) && job.url != null)
                        LinkButton(
                          label: 'Download',
                          onPressed: () => launchUrl(Uri.parse(job.url!)),
                        )
                      else if (job.isExpired(now) ||
                          job.status == ExportStatus.failed)
                        LinkButton(
                          label: 'Create again',
                          onPressed: () => create(job.kind, job.format),
                        )
                      else
                        const SizedBox(),
                    ],
                ],
              ),
          ],
        );
      }),
    );
  }
}
