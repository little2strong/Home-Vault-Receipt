import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/add_possession_controller.dart';

/// 56 · Serial number
class SerialNumberView extends GetView<AddPossessionController> {
  const SerialNumberView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Keep the exact\nnumber.',
      subtitle: 'Review the label before saving.',
      roadmap: true,
      actions: [
        VaultButton.secondary(label: 'Skip', onPressed: controller.finish),
        VaultButton(
          label: 'Confirm serial',
          onPressed: controller.confirmSerial,
        ),
      ],
      children: [
        InfoCard(
          title: 'Photograph the label',
          subtitle: 'Reads a sample serial in this preview',
          leading: const Icon(Icons.photo_camera_outlined),
          onTap: controller.readLabel,
        ),
        const SizedBox(height: 8),
        VaultTextField(
          label: 'Recognised serial',
          controller: controller.serialController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => controller.labelPhotographed.refresh(),
        ),
        VaultTextField(
          label: 'Model number',
          hint: 'Optional',
          controller: controller.modelController,
          textCapitalization: TextCapitalization.characters,
        ),
        Obx(() {
          final clash = controller.serialClash;
          return Column(
            children: [
              VaultSelectField(
                label: 'Label photograph',
                value: controller.labelPhotographed.value
                    ? 'Attached · sample'
                    : 'Not attached',
              ),
              VaultSelectField(
                label: 'Duplicate check',
                value: clash == null
                    ? 'No matching record'
                    : 'Same serial as ${clash.name}',
                warning: clash == null ? null : 'Check before saving.',
              ),
            ],
          );
        }),
      ],
    );
  }
}
