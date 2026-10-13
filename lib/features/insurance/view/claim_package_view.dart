import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 79 · Claim package
class ClaimPackageView extends GetView<InsuranceController> {
  const ClaimPackageView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'An organised\nevidence pack.',
      subtitle: 'Review before sending to an insurer.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Generate package',
          onPressed: controller.generatePackage,
        ),
      ],
      children: const [
        InfoCard(title: 'Summary PDF', subtitle: 'Incident and affected item'),
        InfoCard(title: 'Inventory', subtitle: 'Purchase values and serials'),
        InfoCard(
          title: 'Evidence archive',
          subtitle: 'Originals and damage photos',
        ),
        InfoCard(title: 'Sharing', subtitle: 'Private link · choose expiry'),
      ],
    );
  }
}
