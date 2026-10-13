import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/moving_controller.dart';

/// 89 · Moving box
class MovingBoxView extends GetView<MovingController> {
  const MovingBoxView({super.key});

  @override
  Widget build(BuildContext context) {
    final number = routeArgument<int>(context);
    return Obx(() {
      final b = controller.box(number);
      if (b == null) {
        return const VaultPage(title: 'Box not found', roadmap: true);
      }
      return VaultPage(
        title: 'Box ${b.number} · ${b.room}',
        subtitle:
            '${b.status.label} · ${Formatters.count(b.items.length, 'possession')}',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'View box label',
            onPressed: () => controller.openLabel(number),
          ),
        ],
        children: [
          if (b.items.isEmpty)
            const InfoCard(
              title: 'Empty box',
              subtitle: 'Add possessions as you pack.',
            ),
          for (final item in b.items)
            InfoCard(title: item, subtitle: '${b.room} item'),
        ],
      );
    });
  }
}
