import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/possessions_controller.dart';
import '../widgets/possession_card.dart';

/// 53 · Inventory
class InventoryView extends GetView<PossessionsController> {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.possessions;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction('Inbox', controller.openInbox),
            VaultMenuAction('Rapid inventory', controller.openRapidInventory),
            VaultMenuAction('Find duplicates', controller.openMerge),
          ],
        ),
        title: 'Everything you own.',
        subtitle:
            '${Formatters.count(items.length, 'possession')} · '
            '${Formatters.count(controller.roomCount, 'room')}',
        roadmap: true,
        actions: [
          VaultButton(label: 'Add possession', onPressed: controller.add),
        ],
        children: [
          Wrap(
            spacing: 8,
            children: [
              const StatusChip(label: 'All items'),
              StatusChip(label: 'Rooms', onTap: controller.openRooms),
              StatusChip(
                label: 'Collections',
                onTap: controller.openCollections,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (_, i) => PossessionCard(
              possession: items[i],
              onTap: () => controller.open(items[i]),
            ),
          ),
        ],
      );
    });
  }
}
