import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/vault_ui.dart';

/// 30 Warranties: Active, Expiring within 3 months, Expired — plus the
/// return deadlines the user confirmed.
class WarrantiesView extends StatelessWidget {
  const WarrantiesView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final t = context.textStyles;
    final p = context.palette;
    return Constrained(
      child: Obx(() {
        final expiring = store.warrantiesWith(WarrantyStatus.expiring);
        final active = store.warrantiesWith(WarrantyStatus.active);
        final expired = store.warrantiesWith(WarrantyStatus.expired)
          ..sort((a, b) => b.endDate.compareTo(a.endDate));
        final today = DateTime.now();
        final returns = store.returns.where((r) => r.isOpen(today)).toList();
        final notifications = Get.isRegistered<NotificationService>()
            ? Get.find<NotificationService>()
            : null;
        final off =
            notifications != null &&
            !notifications.granted &&
            (store.profile.value?.notificationsAsked ?? false) &&
            store.warranties.isNotEmpty;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            AppSizes.lg,
            AppSizes.pagePadding,
            AppSizes.xl,
          ),
          children: [
            Semantics(
              header: true,
              child: Text(
                'Warranties',
                style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Within 3 months',
                    value: '${expiring.length}',
                    tone: PillTone.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Active',
                    value: '${active.length}',
                    tone: PillTone.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(label: 'Expired', value: '${expired.length}'),
                ),
              ],
            ),
            if (off) ...[
              const SizedBox(height: 14),
              InfoNote(
                "Reminders are off, so we can't nudge you before these end. "
                'Turn them on in Settings.',
                icon: Icons.notifications_off_outlined,
                warning: true,
                onTap: () => Get.toNamed(Routes.settings),
              ),
            ],
            if (store.warranties.isEmpty && returns.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyState(
                  icon: Icons.shield_outlined,
                  title: 'No warranties yet',
                  message:
                      'Open an item and add its warranty end date. We remind '
                      'you 3 months and 2 weeks before it ends.',
                ),
              ),
            if (expiring.isNotEmpty) ...[
              const SectionLabel('Ending within 3 months'),
              _List(warranties: expiring, today: today),
            ],
            if (returns.isNotEmpty) ...[
              const SectionLabel('Return deadlines'),
              ListCard(
                children: [
                  for (final r in returns)
                    RowTile(
                      title: r.label ?? r.shop ?? 'Return',
                      subtitle:
                          'Return by ${Formatters.medium(r.deadline)}'
                          '${r.shop == null ? '' : ' · ${r.shop}'}',
                      trailing: Pill(
                        Formatters.daysRemaining(r.daysLeft(today)),
                        tone: r.daysLeft(today) <= 7
                            ? PillTone.amber
                            : PillTone.green,
                      ),
                      onTap: () => Get.toNamed(Routes.receipt(r.receiptId)),
                    ),
                ],
              ),
            ],
            if (active.isNotEmpty) ...[
              const SectionLabel('Active'),
              _List(warranties: active, today: today),
            ],
            if (expired.isNotEmpty) ...[
              const SectionLabel('Expired'),
              _List(warranties: expired, today: today),
            ],
            const SizedBox(height: 8),
            Text(
              'Dates are the ones you confirmed. Check the terms with the '
              'shop or maker before you claim.',
              style: TextStyle(color: p.muted),
            ),
          ],
        );
      }),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.warranties, required this.today});

  final List<Warranty> warranties;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListCard(
      children: [
        for (final w in warranties)
          RowTile(
            title: w.itemName ?? 'Item',
            titleColor: w.statusOn(today) == WarrantyStatus.expired
                ? p.muted
                : null,
            subtitle:
                '${w.statusOn(today) == WarrantyStatus.expired ? 'Ended' : 'Ends'} '
                '${Formatters.medium(w.endDate)}${w.shop == null ? '' : ' · ${w.shop}'}',
            trailing: switch (w.statusOn(today)) {
              WarrantyStatus.expiring => Pill(
                Formatters.daysRemaining(w.daysLeft(today)),
                tone: PillTone.amber,
              ),
              WarrantyStatus.active => const Pill(
                'Active',
                tone: PillTone.green,
              ),
              WarrantyStatus.expired => const Pill(
                'Expired',
                tone: PillTone.grey,
              ),
            },
            onTap: () => Get.toNamed(Routes.item(w.itemId)),
          ),
      ],
    );
  }
}
