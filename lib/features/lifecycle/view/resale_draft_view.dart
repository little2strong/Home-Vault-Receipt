import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/lifecycle_controller.dart';

/// 91 · Resale draft
class ResaleDraftView extends RouteView<LifecycleController> {
  const ResaleDraftView({super.key});

  @override
  Widget buildWith(BuildContext context, LifecycleController controller) {
    final p = controller.possession;
    return VaultPage(
      title: 'Ready for its next\nhome.',
      subtitle: 'Review the listing before publishing elsewhere.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Save listing draft',
          onPressed: controller.saveListingDraft,
        ),
      ],
      children: [
        VaultTextField(label: 'Title', controller: controller.resaleTitle),
        VaultSelectField(label: 'Condition', value: p?.condition.label ?? ''),
        VaultTextField(
          label: 'Accessories',
          hint: 'e.g. Case and charging cable',
          controller: controller.accessories,
        ),
        VaultTextField(
          label: 'Price',
          hint: 'User-entered asking price',
          controller: controller.resalePrice,
          validator: Validators.optionalAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        VaultTextField(
          label: 'Description',
          controller: controller.resaleDescription,
          maxLines: 3,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}
