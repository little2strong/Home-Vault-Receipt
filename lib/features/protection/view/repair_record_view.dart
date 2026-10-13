import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/protection_controller.dart';

/// 73 · Repair record
class RepairRecordView extends GetView<ProtectionController> {
  const RepairRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'A fix worth\nremembering.',
      subtitle: 'Attach the invoice and repair details.',
      roadmap: true,
      actions: [
        VaultButton(label: 'Save repair', onPressed: controller.saveRepair),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: Obx(
            () => Column(
              children: [
                VaultSelectField(
                  label: 'Item',
                  value: controller.item.value ?? 'Choose item',
                  placeholder: controller.item.value == null,
                  onTap: () => controller.pickItem(context),
                ),
                VaultTextField(
                  label: 'Problem',
                  hint: 'e.g. Rear brake cable worn',
                  controller: controller.workController,
                  validator: Validators.required,
                ),
                VaultTextField(
                  label: 'Provider',
                  hint: 'e.g. Local cycle workshop',
                  controller: controller.providerController,
                  validator: Validators.required,
                ),
                VaultTextField(
                  label: 'Cost',
                  controller: controller.costController,
                  validator: Validators.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                VaultSelectField(
                  label: 'Repair date',
                  value: Formatters.date(
                    controller.date.value ?? controller.today,
                  ),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => controller.pickDateFor(context, controller.date),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
