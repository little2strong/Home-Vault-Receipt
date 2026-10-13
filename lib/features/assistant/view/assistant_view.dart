import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/assistant_controller.dart';

/// 96 · Assistant
class AssistantView extends GetView<AssistantController> {
  const AssistantView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return VaultPage(
      body: Column(
        children: [
          const VaultPageIntro(
            title: 'Ask your vault.',
            subtitle: 'Answers link to your own records.',
          ),
          Expanded(
            child: Obx(
              () => ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.pagePadding,
                ),
                children: [
                  if (controller.messages.isEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final s in AssistantController.suggestions)
                          StatusChip(label: s, onTap: () => controller.ask(s)),
                      ],
                    ),
                  for (final m in controller.messages)
                    _Bubble(message: m, onLink: controller.openLink),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                AppSizes.sm,
                AppSizes.pagePadding,
                AppSizes.md,
              ),
              child: TextField(
                controller: controller.input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.ask(),
                decoration: InputDecoration(
                  hintText: 'Ask about your vault…',
                  suffixIcon: IconButton(
                    tooltip: 'Send',
                    onPressed: controller.ask,
                    icon: Icon(Icons.send_rounded, color: p.primary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onLink});

  final AssistantMessage message;
  final ValueChanged<AssistantLink> onLink;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = message.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: user ? p.primary : p.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: user ? p.onPrimary : p.ink,
              ),
            ),
            for (final link in message.links)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => onLink(link),
                child: Text(link.label),
              ),
          ],
        ),
      ),
    );
  }
}
