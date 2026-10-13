import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/receipt_illustration.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/save_result_controller.dart';

/// 31 · Saved confirmation
class SavedView extends RouteView<SaveResultController> {
  const SavedView({super.key});

  @override
  Widget buildWith(BuildContext context, SaveResultController controller) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.done();
      },
      child: Obx(() {
        final r = controller.receipt;
        return VaultPage(
          header: VaultHeader.back(onBack: controller.done),
          title: 'One less thing\nto keep track of.',
          subtitle: r != null && r.hasOriginal
              ? 'Your receipt and original have been saved.'
              : 'Your receipt has been saved.',
          actions: [
            VaultButton.secondary(label: 'Done', onPressed: controller.done),
            VaultButton(
              label: 'View receipt',
              onPressed: controller.viewReceipt,
            ),
          ],
          children: [
            const ReceiptIllustration(height: 170),
            if (r != null) ...[
              InfoCard(
                title: r.retailer,
                subtitle:
                    '${r.headline} · ${Money.format(r.total, currency: r.currency)}',
              ),
              r.returnDeadline == null
                  ? InfoCard(
                      title: 'No return deadline',
                      subtitle: 'Add a verified date any time.',
                      onTap: controller.addReturnDate,
                    )
                  : InfoCard(
                      title: 'Return reminder',
                      subtitle:
                          '${Formatters.dayMonth(r.returnDeadline!)} · '
                          'confirmed by you',
                    ),
            ],
          ],
        );
      }),
    );
  }
}
