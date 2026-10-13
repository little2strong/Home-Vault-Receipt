import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/rooms_controller.dart';

/// 64 · Room scan review
class RoomScanReviewView extends GetView<RoomsController> {
  const RoomScanReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.selectedDetections.length;
      return VaultPage(
        title: 'What belongs in your\nvault?',
        subtitle: 'Select detected items and verify their identity.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Create ${Formatters.count(count, 'draft')}',
            onPressed: count == 0 ? null : controller.createDrafts,
          ),
        ],
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(label: '$count selected'),
          ),
          const SizedBox(height: 12),
          for (final (i, (name, note)) in controller.detected.indexed)
            CheckCard(
              title: name,
              subtitle: note,
              checked: controller.selectedDetections.contains(i),
              onChanged: (v) => controller.toggleDetection(i, v),
            ),
        ],
      );
    });
  }
}
