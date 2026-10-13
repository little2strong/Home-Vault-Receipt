import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/review_controller.dart';

/// 24 · Review multiple items
class ReviewItemsView extends RouteView<ReviewController> {
  const ReviewItemsView({super.key});

  @override
  Widget buildWith(BuildContext context, ReviewController controller) {
    return Obx(() {
      final draft = controller.draft;
      final items = controller.items;
      final hint = controller.totalsHint;
      return VaultPage(
        title: 'Keep what matters.',
        subtitle: draft == null
            ? null
            : 'A ${draft.retailer} receipt can contain several products.',
        actions: [
          VaultButton(
            label: 'Confirm & save',
            loading: controller.isBusy.value,
            onPressed: controller.confirmAndSave,
          ),
        ],
        children: [
          Row(
            children: [
              StatusChip(
                label: '${controller.selectedItemIds.length} selected',
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Tap the pencil to edit',
                  style: context.textStyles.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items)
            CheckCard(
              title: item.name,
              subtitle:
                  '${item.quantity} × '
                  '${Money.format(item.lineTotal ~/ item.quantity, currency: draft!.currency)}'
                  ' · ${item.category.shortLabel}',
              checked: controller.selectedItemIds.contains(item.id),
              onChanged: (v) => controller.toggleItem(item.id, v),
              onEdit: () => controller.editItem(item),
            ),
          InfoCard(
            title: '+ Add a missing product',
            tone: CardTone.tonal,
            onTap: controller.editItem,
          ),
          if (hint != null)
            Text(
              hint,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.palette.warningInk,
              ),
            ),
        ],
      );
    });
  }
}
