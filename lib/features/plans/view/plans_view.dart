import 'package:flutter/material.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_page.dart';

/// 98 · Future plan comparison. Static: pricing is undecided.
class PlansView extends StatelessWidget {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return const VaultPage(
      title: 'Plans, when we are\nready.',
      subtitle: 'The current release is a free pilot.',
      roadmap: true,
      children: [
        InfoCard(title: 'Free', subtitle: 'Basic receipt records'),
        InfoCard(title: 'Plus', subtitle: 'Proposed advanced ownership tools'),
        InfoCard(title: 'Family', subtitle: 'Proposed shared household access'),
        InfoCard(
          title: 'Pricing',
          subtitle: 'To be decided after pilot results',
        ),
      ],
    );
  }
}
