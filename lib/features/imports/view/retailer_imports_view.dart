import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../widgets/roadmap_dialog.dart';

/// 87 · Retailer imports
class RetailerImportsView extends StatelessWidget {
  const RetailerImportsView({super.key});

  @override
  Widget build(BuildContext context) {
    void explain() => showRoadmapDialog(
      context,
      'Retailer imports',
      'Supported retailers will connect through their own authorised '
          'sign-in. You can preview found purchases and revoke access at any '
          'time.',
    );

    return VaultPage(
      title: 'Your purchase history',
      subtitle: 'Availability depends on supported integrations.',
      roadmap: true,
      actions: [
        VaultButton(label: 'Review supported retailers', onPressed: explain),
      ],
      children: const [
        InfoCard(
          title: 'Supported retailer',
          subtitle: 'Connect using authorised access',
        ),
        InfoCard(title: 'Found purchases', subtitle: 'Preview before adding'),
        InfoCard(title: 'Disconnect', subtitle: 'Revoke future access'),
      ],
    );
  }
}
