import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/onboarding_controller.dart';

/// 01 · Welcome
class WelcomeView extends GetView<OnboardingController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      header: const VaultHeader.brand(showBell: false),
      title: 'Less paper.\nMore peace of mind.',
      subtitle: 'A private, searchable home for your receipts.',
      actions: [
        TextButton(
          onPressed: controller.skipToSignIn,
          child: const Text('I already have an account'),
        ),
        VaultButton(label: 'Get started', onPressed: controller.showHowItWorks),
      ],
      children: [
        const SizedBox(height: AppSizes.lg),
        const ReceiptIllustration(height: 210),
        const Center(child: StatusChip(label: 'Private by default')),
        const SizedBox(height: AppSizes.md),
        Text(
          'Scan purchases. Keep the proof.\nFind it whenever you need it.',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.palette.muted,
          ),
        ),
      ],
    );
  }
}
