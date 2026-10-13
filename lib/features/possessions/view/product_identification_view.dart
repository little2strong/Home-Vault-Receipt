import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/add_possession_controller.dart';
import '../widgets/possession_card.dart';

/// 55 · Product identification
class ProductIdentificationView extends GetView<AddPossessionController> {
  const ProductIdentificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final created = controller.created.value;
    return VaultPage(
      title: 'Is this your product?',
      subtitle: 'Confirm the suggested identification.',
      roadmap: true,
      actions: [
        VaultButton.secondary(
          label: 'Skip for now',
          onPressed: controller.finish,
        ),
        VaultButton(
          label: 'Confirm product',
          onPressed: controller.confirmProduct,
        ),
      ],
      children: [
        Container(
          height: 140,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p.tonal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: created == null
              ? null
              : Icon(
                  PossessionCard.iconFor(created.category),
                  size: 64,
                  color: p.primary,
                ),
        ),
        InfoCard(
          title: 'Suggested product',
          subtitle: controller.suggestedProduct,
        ),
        InfoCard(
          title: 'Model',
          subtitle: created?.brandModel == null
              ? 'Exact model unconfirmed'
              : '${created!.brandModel} · exact model unconfirmed',
        ),
        const InfoCard(
          title: 'What to check',
          subtitle: 'Verify the model label before saving.',
        ),
      ],
    );
  }
}
