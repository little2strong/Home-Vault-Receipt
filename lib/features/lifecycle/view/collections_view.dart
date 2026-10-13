import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/collections_controller.dart';

/// 93 · Collections
class CollectionsView extends GetView<CollectionsController> {
  const CollectionsView({super.key});

  void _showCollection(BuildContext context, String name) {
    final items = controller.itemsIn(name);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name, style: sheet.textStyles.titleLarge),
              const SizedBox(height: AppSizes.md),
              if (items.isEmpty)
                const InfoCard(
                  title: 'Empty',
                  subtitle: 'Add items from their detail page.',
                ),
              for (final p in items)
                InfoCard(
                  title: p.name,
                  subtitle: p.room,
                  onTap: () {
                    Navigator.of(sheet).pop();
                    controller.openItem(p);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => VaultPage(
        title: 'The things you\ncollect.',
        subtitle: 'Custom groups with supporting evidence.',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'Create collection',
            onPressed: () => controller.create(context),
          ),
        ],
        children: [
          for (final name in controller.collections)
            InfoCard(
              title: name,
              subtitle: Formatters.count(
                controller.itemsIn(name).length,
                'item',
              ),
              onTap: () => _showCollection(context, name),
            ),
        ],
      ),
    );
  }
}
