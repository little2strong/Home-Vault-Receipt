import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/rooms_controller.dart';

/// 61 · Rooms
class RoomsView extends GetView<RoomsController> {
  const RoomsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        header: VaultHeader.back(
          menu: [VaultMenuAction('Scan a room', controller.scan)],
        ),
        title: 'Room by room.',
        subtitle: 'Organise possessions by where they belong.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add room',
            onPressed: () => controller.addRoom(context),
          ),
        ],
        children: [
          for (final room in controller.rooms)
            InfoCard(
              title: room,
              subtitle: Formatters.count(
                controller.inRoom(room).length,
                'item',
              ),
              onTap: () => controller.openRoom(room),
            ),
        ],
      ),
    );
  }
}
