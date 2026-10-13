import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../widgets/roadmap_dialog.dart';

/// 86 · Email imports. Nothing connects in this build.
class EmailImportsView extends StatelessWidget {
  const EmailImportsView({super.key});

  @override
  Widget build(BuildContext context) {
    void explain() => showRoadmapDialog(
      context,
      'Email import',
      'Connecting a mailbox is planned. When it arrives you will choose the '
          'mailbox, see exactly what is read, and review every receipt before '
          'it is saved.',
    );

    return VaultPage(
      title: 'Bring receipts into\nyour vault.',
      subtitle: 'Connect deliberately. Review before saving.',
      roadmap: true,
      actions: [VaultButton(label: 'Set up email import', onPressed: explain)],
      children: [
        const InfoCard(
          title: 'Forwarding address',
          subtitle: 'Shown after account setup',
        ),
        InfoCard(title: 'Gmail', subtitle: 'Not connected', onTap: explain),
        InfoCard(title: 'Outlook', subtitle: 'Not connected', onTap: explain),
        const InfoCard(
          title: 'Import review',
          subtitle: 'Nothing added without confirmation',
        ),
      ],
    );
  }
}
