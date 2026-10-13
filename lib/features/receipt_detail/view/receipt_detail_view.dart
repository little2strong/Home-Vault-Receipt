import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_blocks.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/receipt_detail_controller.dart';

/// 32 · Receipt detail
class ReceiptDetailView extends RouteView<ReceiptDetailController> {
  const ReceiptDetailView({super.key});

  @override
  Widget buildWith(BuildContext context, ReceiptDetailController controller) {
    return Obx(() {
      final r = controller.receipt;
      if (r == null) {
        return const VaultPage(
          body: MessageView(
            icon: Icons.receipt_long_outlined,
            title: 'Receipt not found',
            message: 'It may have been deleted.',
          ),
        );
      }
      final days = r.daysUntilReturn(controller.today);
      final deadlineSubtitle = r.returnDeadline == null
          ? 'Not set · add a verified date'
          : '${Formatters.date(r.returnDeadline!)} · '
                '${days != null && days < 0 ? 'closed' : 'confirmed'}';

      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction('Edit receipt', controller.openEdit),
            VaultMenuAction(
              'Delete receipt',
              controller.openDelete,
              destructive: true,
            ),
          ],
        ),
        title: r.retailer,
        subtitle: 'Purchased ${Formatters.date(r.purchaseDate)}',
        actions: [
          VaultButton(
            label: r.hasOriginal
                ? 'View original receipt'
                : 'No original attached',
            onPressed: r.hasOriginal ? controller.openOriginal : null,
          ),
        ],
        children: [
          if (!r.isSaved)
            InfoCard(
              title: r.status.label,
              subtitle: 'This record is not in your vault yet.',
              tone: CardTone.warning,
              onTap: controller.openPending,
            ),
          HeroCard(
            label: 'Total purchase',
            value: Money.format(r.total, currency: r.currency),
            large: true,
          ),
          for (final item in r.items)
            InfoCard(
              title: item.name,
              subtitle: '${item.category.label} · quantity ${item.quantity}',
              trailingText: Money.format(item.lineTotal, currency: r.currency),
              onTap: () => controller.editItem(item),
            ),
          if (!r.itemsMatchTotal)
            NoticeBanner(
              text:
                  'Products add up to '
                  '${Money.format(r.itemsTotal, currency: r.currency)}',
              detail: 'The receipt total may include delivery or discounts.',
              tone: NoticeTone.warning,
            ),
          InfoCard(
            title: 'Return deadline',
            subtitle: deadlineSubtitle,
            trailingText: days != null && days >= 0
                ? Formatters.daysRemaining(days)
                : null,
            onTap: controller.openDeadline,
          ),
          if (r.reference != null)
            InfoCard(title: 'Receipt reference', subtitle: r.reference),
          if (r.notes != null) InfoCard(title: 'Notes', subtitle: r.notes),
          InfoCard(title: 'Source', subtitle: r.source.label),
          const SizedBox(height: 4),
          if (r.hasOriginal)
            Text(
              'Original ${controller.isPdf ? 'document' : 'image'} hidden '
              'until you open it.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.palette.muted,
              ),
            ),
        ],
      );
    });
  }
}
