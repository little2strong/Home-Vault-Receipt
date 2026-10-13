import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/ownership_models.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/rooms_controller.dart';

/// 62 · Room detail
class RoomDetailView extends GetView<RoomsController> {
  const RoomDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final room = routeArgument<String>(context);
    return Obx(() {
      final items = controller.inRoom(room);
      return VaultPage(
        header: VaultHeader.back(
          menu: [VaultMenuAction('Scan this room', controller.scan)],
        ),
        title: room,
        subtitle: controller.roomSummary(room),
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add item to room',
            onPressed: () => controller.addItem(room),
          ),
        ],
        children: [
          if (items.isEmpty)
            const InfoCard(
              title: 'Nothing here yet',
              subtitle: 'Add an item or scan the room.',
            ),
          for (final p in items)
            InfoCard(
              title: p.name,
              subtitle: [
                p.category.shortLabel,
                if (p.status != OwnershipStatus.owned) p.status.label,
                if (p.purchasePrice != null)
                  Money.formatWhole(p.purchasePrice!),
              ].join(' · '),
              onTap: () => controller.openPossession(p),
            ),
        ],
      );
    });
  }
}
