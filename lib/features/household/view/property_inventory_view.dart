import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/household_controller.dart';

/// 85 · Property inventory
class PropertyInventoryView extends GetView<HouseholdController> {
  const PropertyInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'Property records',
        subtitle: 'Appliances and furnishings by property.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add property item',
            onPressed: controller.addPropertyItem,
          ),
        ],
        children: [
          for (final MapEntry(key: room, value: items)
              in controller.byRoom.entries)
            InfoCard(
              title: 'Main home · ${room.toLowerCase()}',
              subtitle: items.map((p) => p.name).join(', '),
            ),
        ],
      ),
    );
  }
}
