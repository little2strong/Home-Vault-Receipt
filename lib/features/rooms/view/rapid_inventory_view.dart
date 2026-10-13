import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/rooms_controller.dart';

/// 65 · Rapid inventory
class RapidInventoryView extends GetView<RoomsController> {
  const RapidInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'Keep capturing.',
        subtitle: 'Finish the details together afterwards.',
        roadmap: true,
        actions: [
          if (controller.rapidDrafts.isNotEmpty)
            VaultButton.secondary(
              label: 'Finish and review',
              onPressed: controller.finishRapid,
            ),
          VaultButton(
            label: 'Capture next item',
            onPressed: () => controller.captureNext(context),
          ),
        ],
        children: [
          const DocumentPreviewCard(
            title: 'Quick capture',
            subtitle: 'One photo per item',
            icon: Icons.photo_camera_outlined,
          ),
          for (final (i, name) in controller.rapidDrafts.indexed)
            InfoCard(title: name, subtitle: 'Draft ${i + 1} · photo added'),
        ],
      ),
    );
  }
}
