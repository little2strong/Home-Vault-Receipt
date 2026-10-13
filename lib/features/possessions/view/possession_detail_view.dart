import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/route_view.dart';
import '../../../core/widgets/vault_button.dart';
import '../../../core/widgets/vault_header.dart';
import '../../../core/widgets/vault_page.dart';
import '../controller/possession_detail_controller.dart';
import '../widgets/possession_card.dart';

/// 57 · Possession detail
class PossessionDetailView extends RouteView<PossessionDetailController> {
  const PossessionDetailView({super.key});

  @override
  Widget buildWith(
    BuildContext context,
    PossessionDetailController controller,
  ) {
    return Obx(() {
      final p = controller.possession;
      if (p == null) {
        return const VaultPage(
          body: MessageView(
            icon: Icons.inventory_2_outlined,
            title: 'Item not found',
            message: 'It may have been removed.',
          ),
        );
      }
      final palette = context.palette;
      return VaultPage(
        header: VaultHeader.back(
          menu: [
            VaultMenuAction(
              'Gallery',
              () => controller.open(Routes.itemGallery),
            ),
            VaultMenuAction(
              'Timeline',
              () => controller.open(Routes.ownershipTimeline),
            ),
            VaultMenuAction(
              'Ownership status',
              () => controller.open(Routes.ownershipStatus),
            ),
            VaultMenuAction(
              'Resale draft',
              () => controller.open(Routes.resaleDraft),
            ),
            VaultMenuAction(
              'Share securely',
              () => controller.open(Routes.secureSharing),
            ),
            if (p.warrantyExpiry != null)
              VaultMenuAction(
                'Warranty',
                () => controller.open(Routes.warrantyAssistant),
              ),
          ],
        ),
        title: p.name,
        subtitle:
            '${p.room} · ${p.status.label.toLowerCase()} · '
            '${p.condition.label.toLowerCase()} condition',
        roadmap: true,
        actions: [
          VaultButton(
            label: 'View documents',
            onPressed: () => controller.open(Routes.itemDocuments),
          ),
        ],
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: palette.tonal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              PossessionCard.iconFor(p.category),
              size: 72,
              color: palette.primary,
            ),
          ),
          InfoCard(
            title: 'Purchase record',
            subtitle: controller.purchaseLine,
            onTap: p.receiptId == null ? null : controller.openReceipt,
          ),
          InfoCard(
            title: 'Serial number',
            subtitle: p.serialNumber ?? 'Not recorded',
            tone: p.hasSerial ? CardTone.plain : CardTone.warning,
          ),
          InfoCard(
            title: 'Documents',
            subtitle: p.documents.isEmpty
                ? 'None yet'
                : p.documents
                      .where((d) => !d.missing)
                      .map((d) => d.title)
                      .join(', '),
            onTap: () => controller.open(Routes.itemDocuments),
          ),
          InfoCard(
            title: 'Photos',
            subtitle: Formatters.count(p.photos.length, 'photo'),
            onTap: () => controller.open(Routes.itemGallery),
          ),
          if (p.warrantyExpiry != null)
            InfoCard(
              title: 'Warranty',
              subtitle: 'Ends ${Formatters.date(p.warrantyExpiry!)}',
              onTap: () => controller.open(Routes.warrantyAssistant),
            ),
        ],
      );
    });
  }
}
