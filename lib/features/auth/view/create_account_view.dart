import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/create_account_controller.dart';
import '../widgets/password_visibility_button.dart';

/// 04 · Create account
class CreateAccountView extends GetView<CreateAccountController> {
  const CreateAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Start with one\nreceipt.',
      subtitle: 'A free pilot. No payment details needed.',
      actions: [
        TextButton(
          onPressed: controller.openSignIn,
          child: const Text('Already have an account? Sign in'),
        ),
        Obx(
          () => VaultButton(
            label: 'Create account',
            loading: controller.isBusy.value,
            onPressed: controller.createAccount,
          ),
        ),
      ],
      children: [
        Form(
          key: controller.formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => controller.errorMessage.value == null
                      ? const SizedBox.shrink()
                      : NoticeBanner(
                          text: controller.errorMessage.value!,
                          tone: NoticeTone.danger,
                        ),
                ),
                VaultTextField(
                  label: 'Name (optional)',
                  hint: 'Your name',
                  controller: controller.nameController,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                ),
                VaultTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: controller.emailController,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                Obx(
                  () => VaultTextField(
                    label: 'Password',
                    hint: 'Create a strong password',
                    controller: controller.passwordController,
                    validator: Validators.password,
                    obscureText: controller.obscurePassword.value,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => controller.createAccount(),
                    suffix: PasswordVisibilityButton(
                      obscured: controller.obscurePassword.value,
                      onPressed: controller.toggleObscure,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
