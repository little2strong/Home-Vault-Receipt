import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/lifecycle_controller.dart';

/// 95 · Secure sharing
class SecureSharingView extends RouteView<LifecycleController> {
  const SecureSharingView({super.key});

  @override
  Widget buildWith(BuildContext context, LifecycleController controller) {
    return VaultPage(
      title: 'Share only what is\nneeded.',
      subtitle: 'Review fields and expiry before creating a link.',
      roadmap: true,
      actions: [
        VaultButton(
          label: 'Create private link',
          onPressed: controller.createLink,
        ),
      ],
      children: [
        VaultSelectField(
          label: 'Record',
          value: controller.possession?.name ?? '',
        ),
        Obx(
          () => Column(
            children: [
              VaultSelectField(
                label: 'Include',
                value: controller.shareInclude.value,
                onTap: () => controller.pickShareInclude(context),
              ),
              const VaultSelectField(label: 'Exclude', value: 'Personal notes'),
              VaultSelectField(
                label: 'Access expiry',
                value: LifecycleController
                    .expiryOptions[controller.shareExpiry.value]
                    .$1,
                onTap: () => controller.pickShareExpiry(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
