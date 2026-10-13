import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/inbox_controller.dart';

/// 66 · Inbox
class InboxView extends GetView<InboxController> {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final drafts = controller.drafts;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction(
              'Find duplicates',
              () => Get.toNamed(Routes.duplicateMerge),
            ),
          ],
        ),
        title: 'Ready for your\nreview.',
        subtitle: 'Discovered items are drafts until you confirm.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Review selected',
            onPressed: controller.selected.isEmpty
                ? null
                : controller.reviewSelected,
          ),
        ],
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip(label: '${controller.selected.length} selected'),
          ),
          const SizedBox(height: 12),
          if (drafts.isEmpty)
            const InfoCard(
              title: 'Inbox empty',
              subtitle: 'New drafts appear here.',
            ),
          for (final d in drafts)
            CheckCard(
              title: d.name,
              subtitle: '${d.origin} · ${d.note}',
              checked: controller.selected.contains(d.id),
              onChanged: (v) => controller.toggle(d.id, v),
            ),
          InfoCard(
            title: '+ Add a missing product',
            tone: CardTone.tonal,
            onTap: () => controller.addMissing(context),
          ),
        ],
      );
    });
  }
}
