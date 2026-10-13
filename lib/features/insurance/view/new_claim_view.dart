import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/insurance_controller.dart';

/// 77 · New claim
class NewClaimView extends GetView<InsuranceController> {
  const NewClaimView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Bring the facts\ntogether.',
      subtitle: 'Choose an incident and affected items.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Create claim workspace',
          onPressed: controller.createWorkspace,
        ),
      ],
      children: [
        Obx(
          () => Column(
            children: [
              VaultSelectField(
                label: 'Incident type',
                value: controller.incidentType.value,
                onTap: () => controller.pickIncidentType(context),
              ),
              VaultSelectField(
                label: 'Incident date',
                value: Formatters.date(
                  controller.incidentDate.value ?? DateTime.now(),
                ),
                icon: Icons.calendar_today_outlined,
                onTap: () => controller.pickIncidentDate(context),
              ),
              VaultSelectField(
                label: 'Affected items',
                value: controller.affectedItem.value ?? 'Choose item',
                placeholder: controller.affectedItem.value == null,
                onTap: () => controller.pickAffectedItem(context),
              ),
            ],
          ),
        ),
        VaultTextField(
          label: 'Notes',
          hint: 'Describe what happened',
          controller: controller.notesController,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
