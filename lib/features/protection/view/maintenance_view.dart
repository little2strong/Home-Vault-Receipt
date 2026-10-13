import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 71 · Maintenance (with repairs below)
class MaintenanceView extends GetView<ProtectionController> {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final upcoming = controller.upcoming;
      final history = controller.history;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction('Log a repair', controller.newRepair),
            VaultMenuAction(
              'Recall alerts',
              () => Get.toNamed(Routes.recallAlert),
            ),
          ],
        ),
        title: 'A little care, on time.',
        subtitle: 'Upcoming maintenance for your possessions.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Add maintenance task',
            onPressed: controller.newMaintenance,
          ),
        ],
        children: [
          for (final m in upcoming)
            InfoCard(
              title: m.item,
              subtitle: m.done
                  ? '${m.work} · next ${Formatters.dayMonth(m.nextDue!)}'
                  : '${m.work} · ${Formatters.dayMonth(m.due)}',
            ),
          if (history.isNotEmpty) ...[
            const SectionLabel('Completed'),
            for (final m in history)
              InfoCard(
                title: m.item,
                subtitle: '${m.work} · ${Formatters.dayMonth(m.due)}',
                trailingText: m.cost == null
                    ? null
                    : Formatters.currency(m.cost!),
              ),
          ],
          if (controller.repairs.isNotEmpty) ...[
            const SectionLabel('Repairs'),
            for (final r in controller.repairs)
              InfoCard(
                title: r.item,
                subtitle: '${r.problem} · ${Formatters.shortDate(r.date)}',
                trailingText: Formatters.currency(r.cost),
              ),
          ],
        ],
      );
    });
  }
}
