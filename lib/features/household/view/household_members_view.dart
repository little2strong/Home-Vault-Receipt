import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/household_controller.dart';

/// 83 · Household members
class HouseholdMembersView extends GetView<HouseholdController> {
  const HouseholdMembersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'Who can access this\nvault?',
        subtitle: 'Main home · explicit roles and permissions.',
        roadmap: true,
        actions: [
          VaultButton(label: 'Invite member', onPressed: controller.openInvite),
        ],
        children: [
          for (final m in controller.members)
            InfoCard(
              title: m.name,
              subtitle: '${m.role.label} · ${m.role.access}',
              trailing: m.pending
                  ? const StatusChip(label: 'Invited', tone: ChipTone.warning)
                  : null,
            ),
        ],
      ),
    );
  }
}
