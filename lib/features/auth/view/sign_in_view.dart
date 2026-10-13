import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/models/user_account.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_fields.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/sign_in_controller.dart';
import '../widgets/password_visibility_button.dart';

/// 03 · Sign in
class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      header: const VaultHeader.brand(showBell: false),
      title: 'Welcome to\nyour vault.',
      subtitle: 'Sign in to save records across devices.',
      actions: [
        Obx(
          () => VaultButton(
            label: 'Sign in',
            loading: controller.isBusy.value,
            onPressed: controller.signIn,
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
                    hint: 'Enter your password',
                    controller: controller.passwordController,
                    validator: Validators.required,
                    obscureText: controller.obscurePassword.value,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => controller.signIn(),
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.openResetPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        VaultButton.secondary(
          label: 'Continue with Apple',
          onPressed: () => controller.signInWith(SignInMethod.apple),
        ),
        const SizedBox(height: AppSizes.sm),
        VaultButton.secondary(
          label: 'Continue with Google',
          onPressed: () => controller.signInWith(SignInMethod.google),
        ),
        const SizedBox(height: AppSizes.sm),
        Center(
          child: TextButton(
            onPressed: controller.openCreateAccount,
            child: const Text('New here? Create an account'),
          ),
        ),
      ],
    );
  }
}
