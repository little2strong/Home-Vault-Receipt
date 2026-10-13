import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/household_controller.dart';

/// 84 · Invite permissions
class InviteView extends GetView<HouseholdController> {
  const InviteView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Share the right\naccess.',
      subtitle: 'Check the recipient and role before inviting.',
      roadmap: true,
      actions: [
        VaultButton(label: 'Send invitation', onPressed: controller.sendInvite),
      ],
      children: [
        Form(
          key: controller.inviteKey,
          child: VaultTextField(
            label: 'Email',
            hint: 'name@example.com',
            controller: controller.inviteEmail,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        Obx(
          () => Column(
            children: [
              VaultSelectField(
                label: 'Role',
                value: controller.inviteRole.value.label,
                onTap: () => controller.pickRole(context),
              ),
              VaultSelectField(
                label: 'Can add records',
                value: controller.canAddRecords ? 'Yes' : 'No',
              ),
              VaultSelectField(
                label: 'Can delete household',
                value: controller.canDeleteHousehold ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
