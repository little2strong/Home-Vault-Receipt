import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../../settings/view/help_view.dart';
import '../../shell/controller/shell_controller.dart';

/// 40 · Pilot quota
class PilotQuotaView extends StatelessWidget {
  const PilotQuotaView({super.key});

  @override
  Widget build(BuildContext context) {
    final receipts = Get.find<ReceiptRepository>();
    return VaultPage(
      title: 'Your pilot vault is full.',
      subtitle:
          '${receipts.savedCount} of ${ReceiptRepository.pilotLimit} receipt '
          'records saved.',
      actions: [
        VaultButton(
          label: 'Manage receipts',
          onPressed: () => ShellController.openTab(ShellTab.receipts),
        ),
      ],
      children: [
        const NoticeBanner(text: 'Limit reached', tone: NoticeTone.warning),
        const InfoCard(
          title: 'Keep your existing records',
          subtitle: 'Your receipts remain available.',
        ),
        InfoCard(
          title: 'Make room',
          subtitle: 'Export or delete records you no longer need.',
          onTap: () => Get.toNamed(Routes.exportData),
        ),
        InfoCard(
          title: 'Need more space?',
          subtitle: 'Contact us about the pilot.',
          onTap: () => HelpView.contactSupport(context),
        ),
      ],
    );
  }
}
