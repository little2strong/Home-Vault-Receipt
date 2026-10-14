import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../data/vault_store.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/receipt.dart';
import '../theme/vault_palette.dart';
import '../utils/formatters.dart';
import 'feedback.dart';
import 'private_image.dart';
import 'vault_ui.dart';

/// Leading square for an item: its thumbnail when it has photos (thumbs
/// only, never originals), otherwise the category icon.
class ItemLeading extends StatelessWidget {
  const ItemLeading(this.item, {super.key, this.size = 52});

  final Item item;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (item.coverThumbPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: SizedBox.square(
          dimension: size,
          child: PrivateImage(
            path: item.coverThumbPath,
            semanticLabel: 'Photo of ${item.name}',
          ),
        ),
      );
    }
    final physical = item.isPhysical;
    return IconTile(
      item.category.icon,
      size: size,
      color: physical ? null : context.palette.background,
      iconColor: physical ? null : context.palette.muted,
    );
  }
}

/// Item row used on Home, Products and Search.
class ItemRow extends StatelessWidget {
  const ItemRow(
    this.item, {
    super.key,
    this.showViewReceipt = false,
    this.subtitle,
    this.highlight,
  });

  final Item item;
  final bool showViewReceipt;
  final String? subtitle;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final line =
        subtitle ??
        [
          if (item.shop != null) item.shop!,
          if (highlight != null && item.purchaseDate != null)
            Formatters.medium(item.purchaseDate!),
          store.roomLabel(item),
        ].join(' · ');
    return RowTile(
      leading: ItemLeading(item),
      title: item.displayName,
      subtitle: line,
      trailingText: money(
        item.value == 0 && item.lineTotalMinor == null ? null : item.value,
        item.currency,
        estimate: item.estimated,
      ),
      highlight: highlight,
      link: showViewReceipt && item.hasReceipt ? 'View receipt' : null,
      onLink: item.receiptId == null
          ? null
          : () => Get.toNamed(
              Routes.original(item.receiptId!),
              arguments: {'itemId': item.id},
            ),
      onTap: () => Get.toNamed(Routes.item(item.id)),
    );
  }
}

/// Receipt row: `Currys · HV-000123`, `3 items incl. …`.
class ReceiptRow extends StatelessWidget {
  const ReceiptRow(
    this.receipt, {
    super.key,
    this.titleOverride,
    this.highlight,
  });

  final Receipt receipt;
  final String? titleOverride;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final count = receipt.itemCount;
    final consumable = Get.find<VaultStore>()
        .itemsOnReceipt(receipt.id)
        .every((i) => i.type == ItemType.consumable);
    final sub = count == 0
        ? receipt.sourceLine
        : consumable
        ? '${Formatters.count(count, 'item')} · Consumable'
        : '${Formatters.count(count, 'item')}${receipt.itemPreview == null ? '' : ' incl. ${receipt.itemPreview}'}';
    return RowTile(
      leading: const IconTile(Icons.receipt_long_outlined, size: 52),
      highlight: highlight,
      title: titleOverride ?? '${receipt.displayShop} · ${receipt.number}',
      subtitle: sub,
      trailingText: money(receipt.totalMinor, receipt.currency),
      onTap: () => Get.toNamed(Routes.receipt(receipt.id)),
    );
  }
}
