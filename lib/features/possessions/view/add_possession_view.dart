import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/add_possession_controller.dart';

/// 54 · Add possession
class AddPossessionView extends GetView<AddPossessionController> {
  const AddPossessionView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Start with the\nessentials.',
      subtitle: 'Build an ownership record at your own pace.',
      roadmap: true,
      actions: [
        VaultButton(label: 'Save possession', onPressed: controller.save),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: Column(
            children: [
              VaultTextField(
                label: 'Item name',
                hint: 'e.g. MacBook Air',
                controller: controller.nameController,
                validator: Validators.required,
                textCapitalization: TextCapitalization.words,
              ),
              VaultTextField(
                label: 'Brand / model',
                hint: 'e.g. Apple · M3 13-inch',
                controller: controller.brandController,
              ),
              Obx(
                () => VaultSelectField(
                  label: 'Room',
                  value: controller.room.value,
                  onTap: () => controller.pickRoom(context),
                ),
              ),
              VaultTextField(
                label: 'Purchase price',
                hint: 'Optional',
                controller: controller.priceController,
                validator: Validators.optionalAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              Obx(
                () => VaultSelectField(
                  label: 'Condition',
                  value: controller.condition.value.label,
                  onTap: () => controller.pickCondition(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
