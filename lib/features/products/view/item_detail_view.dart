import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/item.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../add/view/edit_item_sheet.dart';

class ItemDetailController extends GetxController {
  ItemDetailController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;
  late final String id = Get.parameters['id'] ?? '';
  final photos = <ItemPhoto>[].obs;
  final page = 0.obs;
  StreamSubscription<List<ItemPhoto>>? _sub;

  Item? get item => store.item(id);

  @override
  void onInit() {
    super.onInit();
    _sub = repo.photos(id).listen(photos.assignAll, onError: (_) {});
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  static DraftItem toDraft(Item i) => DraftItem(
    id: i.id,
    name: i.name,
    category: i.category,
    type: i.type,
    purpose: i.purpose,
    carId: i.carId,
    inHome: i.inHome,
    allocations: Map.of(i.allocations),
    quantity: i.quantity,
    unitPriceMinor: i.unitPriceMinor,
    lineTotalMinor: i.lineTotalMinor,
    lineBox: i.lineBox,
    serial: i.serial,
    model: i.model,
    notes: i.notes,
    highValue: i.highValue,
    warrantyEnd: i.warrantyEnd,
    typeTouched: true,
  );

  Future<void> edit() async {
    final i = item;
    if (i == null) return;
    final d = await EditItemSheet.open(
      item: toDraft(i),
      currency: i.currency,
      purchaseDate: i.purchaseDate,
      savedItemId: i.id,
      onViewOnReceipt: i.receiptId == null ? null : viewReceipt,
      onDelete: delete,
    );
    if (d == null) return;
    final physicalHome = d.isPhysical && d.inHome;
    try {
      await repo.updateItem(i.id, {
        'name': d.name,
        'category': d.category.name,
        'type': d.type.name,
        'purpose': d.purpose.name,
        'carId': d.purpose == Purpose.car ? d.carId : null,
        'inHome': physicalHome,
        'allocations': physicalHome ? d.allocations : <String, int>{},
        'roomIds': physicalHome ? d.allocations.keys.toList() : <String>[],
        'quantity': d.quantity,
        'unitPriceMinor': d.unitPriceMinor,
        'lineTotalMinor': d.lineTotalMinor,
        'serial': d.serial,
        'model': d.model,
        'notes': d.notes,
        'highValue': d.highValue,
      });
      Toast.show('Saved');
    } catch (_) {
      Toast.show('That change did not save. Try again.');
    }
  }

  Future<void> changeStatus(BuildContext context) async {
    final i = item;
    if (i == null) return;
    final s = await Pickers.choose<ItemStatus>(
      context,
      title: 'What happened to it?',
      values: ItemStatus.values,
      label: (s) => s == ItemStatus.owned ? 'I still own it' : s.label,
      selected: i.status,
    );
    if (s == null || s == i.status) return;
    await repo.updateItem(i.id, {'status': s.name});
    Toast.show(
      s == ItemStatus.owned
          ? 'Back on your home inventory'
          : 'Marked ${s.label.toLowerCase()} · kept in your records',
    );
  }

  void viewReceipt() {
    final rid = item?.receiptId;
    if (rid == null) return;
    Get.toNamed(Routes.original(rid), arguments: {'itemId': id});
  }

  Future<void> delete() async {
    final context = Get.context!;
    final ok = await Pickers.confirm(
      context,
      title: 'Delete this item?',
      message:
          'Its photos and warranty are deleted too. The receipt it came from '
          'is kept.',
      action: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await repo.deleteItem(id);
      Get.back<void>();
      Toast.show('Item deleted');
    } catch (e) {
      Toast.show('$e');
    }
  }
}

/// 21 Item detail: photos, room, price, warranty and View receipt.
class ItemDetailView extends GetView<ItemDetailController> {
  const ItemDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return Obx(() {
      final item = controller.item;
      if (item == null) {
        return AppPage(
          title: 'Item',
          children: [
            controller.store.loaded.value
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'This item is no longer here',
                    message: 'It may have been deleted on another device.',
                  )
                : const Center(child: CircularProgressIndicator()),
          ],
        );
      }
      final store = controller.store;
      final warranty = store.warrantyFor(item.id);
      final today = DateTime.now();
      final photos = controller.photos;
      final serialPhoto = photos.any(
        (ph) => (ph.label ?? '').toLowerCase().contains('serial'),
      );
      final evidence = [
        if (photos.isNotEmpty) Formatters.count(photos.length, 'photo'),
        if (item.serial != null || serialPhoto) 'serial recorded',
      ];
      return Scaffold(
        bottomNavigationBar: SafeArea(
          child: Constrained(
            shrink: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  if (item.hasReceipt) ...[
                    Expanded(
                      flex: 3,
                      child: VaultButton(
                        label: 'View receipt',
                        icon: Icons.bookmark_border_rounded,
                        onPressed: controller.viewReceipt,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: item.hasReceipt
                        ? VaultButton.secondary(
                            label: 'Photos',
                            onPressed: () =>
                                Get.toNamed(Routes.photos(item.id)),
                          )
                        : VaultButton(
                            label: 'Photos',
                            onPressed: () =>
                                Get.toNamed(Routes.photos(item.id)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Constrained(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PhotoHeader(controller: controller, item: item),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                sliver: SliverList.list(
                  children: [
                    Text(
                      item.displayName,
                      style: t.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      money(
                        item.lineTotalMinor == null &&
                                item.unitPriceMinor == null
                            ? null
                            : item.value,
                        item.currency,
                        estimate: item.estimated,
                      ),
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.estimated)
                      Text(
                        'Your estimate · no receipt',
                        style: TextStyle(color: p.muted),
                      ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Pill(item.type.label, tone: PillTone.green),
                        Pill(item.purpose.label, tone: PillTone.green),
                        if (item.isPhysical && item.inHome)
                          Pill(store.roomLabel(item), tone: PillTone.green),
                        if (item.inInventory)
                          const Pill('In my home', tone: PillTone.green),
                        if (item.highValue)
                          const Pill('High value', tone: PillTone.amber),
                        if (item.status != ItemStatus.owned)
                          Pill(item.status.label, tone: PillTone.grey),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ListCard(
                      children: [
                        DetailRow(
                          'Bought',
                          [
                            if (item.purchaseDate != null)
                              Formatters.medium(item.purchaseDate!)
                            else if (item.yearBought != null)
                              'About ${item.yearBought}',
                            ?item.shop,
                          ].join(' · ').ifEmpty('Not stated'),
                          muted:
                              item.purchaseDate == null &&
                              item.shop == null &&
                              item.yearBought == null,
                        ),
                        DetailRow(
                          'Receipt',
                          item.receiptNumber ?? 'No receipt',
                          valueColor: item.receiptId == null ? null : p.primary,
                          muted: item.receiptId == null,
                          onTap: item.receiptId == null
                              ? null
                              : () => Get.toNamed(
                                  Routes.receipt(item.receiptId!),
                                ),
                        ),
                        if (item.isPhysical)
                          DetailRow(
                            'Warranty',
                            warranty == null
                                ? 'Add end date'
                                : '${warranty.statusOn(today).label} · '
                                      '${warranty.statusOn(today) == WarrantyStatus.expired ? 'ended' : 'ends'} '
                                      '${Formatters.medium(warranty.endDate)}',
                            valueColor: warranty == null
                                ? p.muted
                                : switch (warranty.statusOn(today)) {
                                    WarrantyStatus.active => p.primary,
                                    WarrantyStatus.expiring => p.warningInk,
                                    WarrantyStatus.expired => p.muted,
                                  },
                            onTap: () => Get.toNamed(Routes.warranty(item.id)),
                          ),
                        if (item.serial != null)
                          DetailRow('Serial number', item.serial!),
                        if (item.model != null) DetailRow('Model', item.model!),
                        DetailRow(
                          'Evidence',
                          evidence.isEmpty
                              ? 'No photos yet'
                              : evidence.join(' · '),
                          muted: evidence.isEmpty,
                          onTap: () => Get.toNamed(Routes.photos(item.id)),
                        ),
                        DetailRow(
                          'Status',
                          item.status.label,
                          onTap: () => controller.changeStatus(context),
                        ),
                        if (item.notes != null) DetailRow('Notes', item.notes!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.controller, required this.item});

  final ItemDetailController controller;
  final Item item;

  @override
  Widget build(BuildContext context) {
    final photos = controller.photos;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 320 + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF3E4744)),
          if (photos.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.category.icon, color: Colors.white54, size: 72),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => Get.toNamed(Routes.photos(item.id)),
                    icon: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Add photos',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              itemCount: photos.length,
              onPageChanged: (i) => controller.page.value = i,
              itemBuilder: (_, i) => PrivateImage(
                path: photos[i].path,
                semanticLabel: photos[i].label ?? 'Photo of ${item.name}',
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            top: top + 16,
            child: Row(
              children: [
                const SquareIconButton.back(),
                const Spacer(),
                SquareIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit item',
                  onPressed: controller.edit,
                ),
              ],
            ),
          ),
          if (photos.isNotEmpty)
            Positioned(
              left: 24,
              bottom: 18,
              child: Obx(() {
                final ph =
                    photos[controller.page.value.clamp(0, photos.length - 1)];
                final when = ph.deviceTakenAt ?? ph.serverUploadedAt;
                final how = ph.source == PhotoSource.camera
                    ? 'Taken in Home Vault'
                    : 'Added from gallery';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    [
                      how,
                      if (when != null) Formatters.medium(when),
                      '${controller.page.value + 1} of ${photos.length}',
                    ].join(' · '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
