import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/verify_email_controller.dart';

/// 05 · Verify email
class VerifyEmailView extends GetView<VerifyEmailController> {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      header: const VaultHeader.brand(showBell: false),
      title: 'Check your inbox.',
      subtitle: 'Verify your email before saving to your vault.',
      actions: [
        Obx(
          () => VaultButton.secondary(
            label: controller.secondsUntilResend.value > 0
                ? 'Resend in ${controller.secondsUntilResend.value}s'
                : 'Resend verification',
            onPressed: controller.secondsUntilResend.value > 0
                ? null
                : controller.resend,
          ),
        ),
        Obx(
          () => VaultButton(
            label: 'I have verified my email',
            loading: controller.isChecking.value,
            onPressed: controller.checkVerified,
          ),
        ),
      ],
      children: [
        const ReceiptIllustration(height: 170),
        InfoCard(title: 'Email sent', subtitle: controller.email),
        const InfoCard(
          title: 'Did not receive it?',
          subtitle: 'Check spam or request another email.',
        ),
        InfoCard(
          title: 'Wrong address?',
          subtitle: 'Start again with a different email.',
          onTap: controller.useDifferentEmail,
        ),
      ],
    );
  }
}
