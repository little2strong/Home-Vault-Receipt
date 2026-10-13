import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/inbox_controller.dart';

/// 67 · Duplicate item merge
class DuplicateMergeView extends GetView<InboxController> {
  const DuplicateMergeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pair = controller.mergeCandidate;
      if (pair == null) {
        return const VaultPage(
          title: 'No duplicates found.',
          subtitle: 'Drafts that match an existing item appear here.',
          roadmap: true,
        );
      }
      final (draft, existing) = pair;
      return VaultPage(
        title: 'Bring the records\ntogether.',
        subtitle: 'Choose which details to keep.',
        roadmap: true,
        actions: [
          VaultButton(label: 'Review merge', onPressed: controller.merge),
        ],
        children: [
          InfoCard(
            title: existing.name,
            subtitle:
                'Existing · ${existing.hasReceipt ? 'receipt attached' : 'no receipt'}',
          ),
          InfoCard(
            title: draft.name,
            subtitle: 'New draft · ${draft.origin.toLowerCase()}',
          ),
          InfoCard(
            title: 'Merge preview',
            subtitle:
                'Keep ${existing.name}\'s records and add the draft details.',
          ),
          InfoCard(
            title: 'Save as a separate record',
            tone: CardTone.tonal,
            onTap: controller.keepSeparate,
          ),
        ],
      );
    });
  }
}
