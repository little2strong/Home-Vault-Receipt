import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/reset_password_controller.dart';

/// 06 · Reset password
class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Back into your vault.',
      subtitle: 'We will send a password reset link.',
      actions: [
        Obx(
          () => VaultButton(
            label: controller.sentTo.value == null
                ? 'Send reset link'
                : 'Send again',
            loading: controller.isBusy.value,
            onPressed: controller.sendLink,
          ),
        ),
      ],
      children: [
        Obx(() {
          final sentTo = controller.sentTo.value;
          final error = controller.errorMessage.value;
          if (error != null) {
            return NoticeBanner(text: error, tone: NoticeTone.danger);
          }
          if (sentTo == null) return const SizedBox.shrink();
          return NoticeBanner(
            text: 'Check your inbox',
            detail:
                'If an account exists for $sentTo, a reset link is on its way.',
          );
        }),
        Form(
          key: controller.formKey,
          child: VaultTextField(
            label: 'Email',
            hint: 'you@example.com',
            controller: controller.emailController,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => controller.sendLink(),
          ),
        ),
      ],
    );
  }
}
