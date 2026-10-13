import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/ownership_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/moving_controller.dart';

/// 88 · Moving overview
class MovingView extends GetView<MovingController> {
  const MovingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'One less moving\nworry.',
        subtitle: 'Main home → new home',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Create a box',
            onPressed: () => controller.createBox(context),
          ),
        ],
        children: [
          for (final status in BoxStatus.values)
            InfoCard(
              title: status.label,
              subtitle: () {
                final list = controller.withStatus(status);
                final items = Formatters.count(
                  controller.itemCount(list),
                  'item',
                );
                return list.isEmpty || status == BoxStatus.notPacked
                    ? items
                    : '$items · ${Formatters.count(list.length, 'box', 'boxes')}';
              }(),
            ),
          const SectionLabel('Boxes'),
          for (final b in controller.boxes)
            InfoCard(
              title: 'Box ${b.number} · ${b.room}',
              subtitle:
                  '${b.status.label} · ${Formatters.count(b.items.length, 'possession')}',
              onTap: () => controller.openBox(b),
            ),
        ],
      ),
    );
  }
}
