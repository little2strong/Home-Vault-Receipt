import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/moving_controller.dart';

/// 90 · Box label
class BoxLabelView extends GetView<MovingController> {
  const BoxLabelView({super.key});

  @override
  Widget build(BuildContext context) {
    final number = routeArgument<int>(context);
    final p = context.palette;
    return Obx(() {
      final b = controller.box(number);
      if (b == null) {
        return const VaultPage(title: 'Box not found', roadmap: true);
      }
      return VaultPage(
        title: 'Find it without\nopening it.',
        subtitle: 'Box ${b.number} · ${b.room}',
        roadmap: true,
        actions: [
          VaultButton(label: 'Export label', onPressed: controller.exportLabel),
        ],
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Column(
              children: [
                Text('BOX ${b.number}', style: context.textStyles.titleLarge),
                const SizedBox(height: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.tonal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: p.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'QR placeholder only',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          InfoCard(
            title: 'Status',
            subtitle: b.status.label,
            onTap: () => controller.changeStatus(context, number),
          ),
          InfoCard(
            title: 'Contains',
            subtitle: Formatters.count(b.items.length, 'possession'),
          ),
          InfoCard(title: 'Destination', subtitle: b.destination),
        ],
      );
    });
  }
}
