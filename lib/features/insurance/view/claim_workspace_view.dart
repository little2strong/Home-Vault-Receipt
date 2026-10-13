import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 78 · Claim workspace
class ClaimWorkspaceView extends GetView<InsuranceController> {
  const ClaimWorkspaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final claim = controller.claim;
    final item = controller.claimItem;
    if (claim == null) {
      return const VaultPage(title: 'No claim yet', roadmap: true);
    }
    return VaultPage(
      title:
          '${claim.item} ${claim.incidentType.split(' ').last.toLowerCase()}',
      subtitle: 'Draft claim · 1 affected possession',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Review claim package',
          onPressed: controller.openPackage,
        ),
      ],
      children: [
        InfoCard(
          title: 'Ownership evidence',
          subtitle: [
            if (item?.hasReceipt ?? false) 'Receipt',
            if (item?.hasPhoto ?? false) 'original photos',
          ].join(' and ').ifEmpty('No evidence attached yet'),
          tone: (item?.hasReceipt ?? false) ? CardTone.plain : CardTone.warning,
        ),
        const InfoCard(
          title: 'Damage evidence',
          subtitle: 'Add photographs of the damage',
        ),
        const InfoCard(title: 'Replacement estimate', subtitle: 'Not verified'),
        InfoCard(
          title: 'Incident notes',
          subtitle: claim.notes.isEmpty ? 'None yet' : 'Review before sharing',
        ),
      ],
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
