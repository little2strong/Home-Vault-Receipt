import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/receipt_detail_controller.dart';

/// 36 · Delete receipt
class DeleteReceiptView extends RouteView<ReceiptDetailController> {
  const DeleteReceiptView({super.key});

  @override
  Widget buildWith(BuildContext context, ReceiptDetailController controller) {
    final r = controller.receipt;
    return VaultPage(
      title: 'Delete this receipt?',
      subtitle: r?.hasOriginal ?? false
          ? 'Remove the record and its original document.'
          : 'Remove the record from your vault.',
      actions: [
        VaultButton.secondary(label: AppStrings.cancel, onPressed: Get.back),
        Obx(
          () => VaultButton.danger(
            label: 'Delete receipt',
            loading: controller.isDeleting.value,
            onPressed: controller.delete,
          ),
        ),
      ],
      children: [
        const NoticeBanner(
          text: AppStrings.reviewCarefully,
          tone: NoticeTone.danger,
        ),
        if (r != null)
          InfoCard(
            title:
                '${r.retailer} · ${Money.format(r.total, currency: r.currency)}',
            subtitle: r.headline,
          ),
        const InfoCard(
          title: 'This cannot be undone',
          subtitle: 'Deletion is processed across your live vault.',
        ),
      ],
    );
  }
}
