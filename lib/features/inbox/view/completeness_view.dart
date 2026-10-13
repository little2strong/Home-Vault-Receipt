import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/ownership_models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/inbox_controller.dart';

/// 68 · Completeness
class CompletenessView extends GetView<InboxController> {
  const CompletenessView({super.key});

  static final _checks = <(String, bool Function(Possession))>[
    ('Photo', (p) => p.hasPhoto),
    ('Receipt', (p) => p.hasReceipt),
    ('Serial number', (p) => p.hasSerial),
    ('Purchase details', (p) => p.hasPurchaseDetails),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'Useful records,\nstronger evidence.',
        subtitle: 'Documentation score, not a coverage guarantee.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Fill documentation gaps',
            onPressed: controller.fillGaps,
          ),
        ],
        children: [
          HeroCard(
            label: 'Documentation completeness',
            value: '${controller.percent}%',
            caption: 'Based on evidence, not coverage.',
            large: true,
          ),
          for (final (label, has) in _checks)
            InfoCard(
              title: label,
              subtitle: switch (controller.missing(has)) {
                0 => 'Complete',
                final n => 'Missing on ${Formatters.count(n, 'item')}',
              },
              tone: controller.missing(has) == 0
                  ? CardTone.plain
                  : CardTone.warning,
            ),
        ],
      ),
    );
  }
}
