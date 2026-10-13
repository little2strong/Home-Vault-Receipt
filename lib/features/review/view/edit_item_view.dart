import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/edit_item_controller.dart';

/// 26 · Edit line item
class EditItemView extends RouteView<EditItemController> {
  const EditItemView({super.key});

  @override
  Widget buildWith(BuildContext context, EditItemController controller) {
    return VaultPage(
      header: VaultHeader.back(
        menu: [
          if (!controller.isNew && controller.args.canRemove)
            VaultMenuAction(
              'Remove product',
              controller.remove,
              destructive: true,
            ),
        ],
      ),
      title: controller.isNew
          ? 'Add a product.'
          : 'One product.\nThe right details.',
      subtitle: 'Keep the source description for reference.',
      actions: [
        VaultButton(
          label: controller.isNew ? 'Add product' : 'Save product',
          onPressed: controller.save,
        ),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: Column(
            children: [
              VaultTextField(
                label: 'Product name',
                hint: 'e.g. Wireless headphones',
                controller: controller.nameController,
                validator: Validators.required,
                textCapitalization: TextCapitalization.sentences,
              ),
              VaultTextField(
                label: 'Source description',
                hint: 'As printed on the receipt (optional)',
                controller: controller.sourceController,
                textCapitalization: TextCapitalization.characters,
              ),
              VaultTextField(
                label: 'Quantity',
                controller: controller.quantityController,
                validator: Validators.quantity,
                keyboardType: TextInputType.number,
              ),
              VaultTextField(
                label: 'Line total (${controller.currencySymbol})',
                hint: '0.00',
                controller: controller.totalController,
                validator: Validators.amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              Obx(
                () => VaultSelectField(
                  label: 'Category',
                  value: controller.category.value.label,
                  onTap: () => controller.pickCategory(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
