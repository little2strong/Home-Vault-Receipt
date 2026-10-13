import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/delete_account_controller.dart';

/// 50 · Account deletion
class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Leave with control.',
      subtitle: 'Export anything you want to keep first.',
      actions: [
        VaultButton.secondary(label: AppStrings.cancel, onPressed: Get.back),
        Obx(
          () => VaultButton.danger(
            label: 'Continue to deletion',
            loading: controller.isDeleting.value,
            onPressed: () => controller.deleteAccount(context),
          ),
        ),
      ],
      children: [
        const NoticeBanner(
          text: AppStrings.reviewCarefully,
          tone: NoticeTone.danger,
        ),
        InfoCard(
          title: 'What is removed',
          subtitle:
              'Account, ${Formatters.count(controller.recordCount, 'record')} '
              'and their documents',
        ),
        const InfoCard(
          title: 'Backups',
          subtitle: 'Expire under the published retention policy',
        ),
        const InfoCard(
          title: 'Identity check',
          subtitle: 'Reauthentication required',
        ),
        InfoCard(
          title: 'Export first',
          subtitle: 'Copy your records before they are gone',
          tone: CardTone.tonal,
          onTap: controller.exportFirst,
        ),
      ],
    );
  }
}
