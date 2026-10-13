import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/onboarding_controller.dart';

/// 02 · How it works
class HowItWorksView extends GetView<OnboardingController> {
  const HowItWorksView({super.key});

  @override
  Widget build(BuildContext context) {
    return VaultPage(
      title: 'Snap. Check. Save.',
      subtitle: 'Three small steps. Everything in its place.',
      actions: [VaultButton(label: 'Continue', onPressed: controller.finish)],
      children: const [
        StepTile(
          badge: '01',
          title: 'Photograph or import',
          detail: 'Receipts, screenshots and PDF invoices.',
        ),
        StepTile(
          badge: '02',
          title: 'Check the details',
          detail: 'Correct anything before you save.',
        ),
        StepTile(
          badge: '03',
          title: 'Find it when you need it',
          detail: 'Your original stays attached and private.',
        ),
      ],
    );
  }
}
