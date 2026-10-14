import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/receipt_draft.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/receipt_saver.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../add/controller/capture_flow.dart';
import '../../products/controller/products_controller.dart';
import '../../shell/controller/shell_controller.dart';

// ----------------------------------------------------------- 33 Spending

enum SpendWindow {
  days30('30 days'),
  year('Last year'),
  lifetime('Lifetime');

  const SpendWindow(this.label);
  final String label;
}

/// 33 Spending detail: breakdown by category and purpose, per currency.
class SpendingView extends StatelessWidget {
  const SpendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final arg = Get.arguments;
    final window =
        (arg == 'Last 30 days'
                ? SpendWindow.days30
                : arg == 'Lifetime'
                ? SpendWindow.lifetime
                : SpendWindow.year)
            .obs;
    final p = context.palette;
    return Obx(() {
      final s = store.stats.value;
      final main = store.profile.value?.mainCurrency ?? 'GBP';
      final w = window.value;
      final (totals, receipts, byCat, byPurpose) = switch (w) {
        SpendWindow.days30 => (
          s.last30Days,
          s.receipts30,
          s.byCategory30,
          s.byPurpose30,
        ),
        SpendWindow.year => (
          s.last365Days,
          s.receipts365,
          s.byCategory365,
          s.byPurpose365,
        ),
        SpendWindow.lifetime => (
          s.lifetime,
          s.receiptsLifetime,
          s.byCategoryLifetime,
          s.byPurposeLifetime,
        ),
      };
      final today = DateTime.now();
      final range = switch (w) {
        SpendWindow.days30 =>
          '${Formatters.medium(Dates.addDays(today, -29))} – ${Formatters.medium(today)}',
        SpendWindow.year =>
          '${Formatters.medium(Dates.addDays(Dates.addMonths(today, -12), 1))} – ${Formatters.medium(today)}',
        SpendWindow.lifetime =>
          s.firstPurchase == null
              ? 'All time'
              : 'Since ${Formatters.medium(s.firstPurchase!)}',
      };
      final cats = (byCat[main] ?? const {}).entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = cats.isEmpty ? 1 : cats.first.value;
      final others = totals.keys.where((c) => c != main).toList();
      final purposes = (byPurpose[main] ?? const {}).entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return AppPage(
        title: 'Spending',
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.tonal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final v in SpendWindow.values)
                  Expanded(
                    child: Semantics(
                      selected: v == w,
                      button: true,
                      child: InkWell(
                        onTap: () => window.value = v,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: v == w ? p.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            v.label,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '$range · ${Formatters.count(receipts, 'receipt')}',
            style: TextStyle(color: p.muted, fontWeight: FontWeight.w700),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(totals[main] ?? 0, main),
              style: context.textStyles.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final c in others)
            Text(
              'Also ${Money.format(totals[c]!, currency: c)} in ${c == 'EUR'
                  ? 'euros'
                  : c == 'USD'
                  ? 'US dollars'
                  : c}, counted separately',
              style: TextStyle(color: p.muted),
            ),
          const SizedBox(height: 18),
          VaultCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('By category', style: context.textStyles.titleMedium),
                const SizedBox(height: 8),
                if (cats.isEmpty)
                  Text('Nothing yet.', style: TextStyle(color: p.muted)),
                for (final e in cats.take(8)) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Category.fromName(e.key).label,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Text(
                        Money.format(e.value, currency: main),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: top == 0 ? 0 : e.value / top,
                      minHeight: 8,
                      backgroundColor: p.tonal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (purposes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('By purpose', style: context.textStyles.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in purposes)
                  SizedBox(
                    width: 150,
                    child: StatTile(
                      label: Purpose.fromName(e.key).label,
                      value: Money.format(e.value, currency: main),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'From receipts you confirmed. Items without a receipt are not counted.',
            style: TextStyle(color: p.muted),
          ),
        ],
      );
    });
  }
}

// --------------------------------------------------------------- 34 Cars

/// 34 Cars: named cars and their costs.
class CarsView extends StatelessWidget {
  const CarsView({super.key});

  Future<void> _edit(BuildContext context, [Car? car]) async {
    final name = TextEditingController(text: car?.name);
    final reg = TextEditingController(text: car?.reg);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(car == null ? 'Add a car' : 'Edit ${car.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name, e.g. Golf'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reg,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Registration (optional)',
              ),
            ),
          ],
        ),
        actions: [
          if (car != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: Text(
                'Remove',
                style: TextStyle(color: context.palette.dangerInk),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final repo = Get.find<VaultRepository>();
    if (result == 'save' && name.text.trim().isNotEmpty) {
      await repo.saveCar(id: car?.id, name: name.text, reg: reg.text);
    } else if (result == 'delete' && car != null) {
      await repo.deleteCar(car.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final p = context.palette;
    return Obx(() {
      final main = store.profile.value?.mainCurrency ?? 'GBP';
      return AppPage(
        title: 'Cars',
        subtitle:
            'Name your cars so you can tag fuel, parts and servicing to the right one.',
        actions: [
          VaultButton(label: 'Add a car', onPressed: () => _edit(context)),
        ],
        children: [
          if (store.cars.isEmpty)
            const EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No cars yet',
              message:
                  'Add a car, then choose Purpose: Car when you check a receipt.',
            ),
          for (final car in store.cars) ...[
            Builder(
              builder: (context) {
                final spend =
                    store.stats.value.cars[car.id] ?? const CarSpend();
                final count = store.items
                    .where((i) => i.carId == car.id)
                    .length;
                return VaultCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconTile(Icons.directions_car_outlined),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.name,
                                  style: context.textStyles.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  car.reg ?? 'Registration not added',
                                  style: TextStyle(color: p.muted),
                                ),
                              ],
                            ),
                          ),
                          LinkButton(
                            label: 'Edit',
                            onPressed: () => _edit(context, car),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final (label, m) in [
                        ('Last 30 days', spend.last30Days),
                        ('Last year', spend.last365Days),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: p.muted,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                money(m[main] ?? 0, main),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      LinkButton(
                        label:
                            'See ${Formatters.count(count, 'item')} for ${car.name}',
                        onPressed: () {
                          Get.find<ProductsController>().showFor(
                            ProductFilters(carId: car.id),
                          );
                          Get.until((r) => r.settings.name == Routes.shell);
                          Get.find<ShellController>().tab.value = 1;
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    });
  }
}

// ------------------------------------------------------------- 35 Export

class ExportController extends GetxController {
  ExportController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;
  final kind = ExportKind.inventory.obs;
  final format = ExportFormat.pdf.obs;
  final photos = true.obs;
  final receiptNumbers = true.obs;
  final withoutReceipts = true.obs;
  final busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ExportKind) kind.value = Get.arguments as ExportKind;
  }

  int get count => switch (kind.value) {
    ExportKind.inventory =>
      store.inventory
          .where((i) => withoutReceipts.value || i.hasReceipt)
          .length,
    ExportKind.products =>
      store.items.where((i) => withoutReceipts.value || i.hasReceipt).length,
    ExportKind.archive => store.items.length,
  };

  Future<void> create() async {
    busy.value = true;
    try {
      final f = kind.value == ExportKind.archive
          ? ExportFormat.zip
          : format.value;
      final id = await repo.requestExport(
        kind: kind.value,
        format: f,
        includePhotos: photos.value,
        includeReceiptNumbers: receiptNumbers.value,
        includeWithoutReceipts: withoutReceipts.value,
      );
      await Get.offNamed(Routes.exportReady(id));
    } catch (_) {
      Toast.show("The download couldn't start. Check your connection.");
    } finally {
      busy.value = false;
    }
  }
}

/// 35 Export: choose list, format and what to include. Always free.
class ExportView extends GetView<ExportController> {
  const ExportView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final archive = controller.kind.value == ExportKind.archive;
      final fmt = archive ? ExportFormat.zip : controller.format.value;
      return AppPage(
        title: 'Download a list',
        actions: [
          VaultButton(
            label:
                'Create ${fmt == ExportFormat.both ? 'PDF and CSV' : fmt.label} · ${Formatters.count(controller.count, 'item')}',
            loading: controller.busy.value,
            onPressed: controller.create,
          ),
        ],
        children: [
          Text('Which list?', style: context.textStyles.titleMedium),
          const SizedBox(height: 10),
          for (final k in ExportKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VaultCard(
                borderColor: controller.kind.value == k ? p.primary : null,
                onTap: () => controller.kind.value = k,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      controller.kind.value == k
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: controller.kind.value == k ? p.primary : p.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.label, style: context.textStyles.titleMedium),
                          Text(k.description, style: TextStyle(color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!archive) ...[
            const FieldLabel('Format'),
            Row(
              children: [
                for (final f in const [
                  ExportFormat.pdf,
                  ExportFormat.csv,
                  ExportFormat.both,
                ]) ...[
                  Expanded(
                    child: ChoicePill(
                      label: f.label,
                      selected: controller.format.value == f,
                      onTap: () => controller.format.value = f,
                    ),
                  ),
                  if (f != ExportFormat.both) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
          const FieldLabel('Include'),
          VaultCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (label, rx) in [
                  ('Item photos', controller.photos),
                  ('Receipt numbers', controller.receiptNumbers),
                  ('Items without receipts', controller.withoutReceipts),
                ])
                  CheckboxListTile(
                    title: Text(label, style: const TextStyle(fontSize: 17)),
                    value: rx.value,
                    onChanged: (v) => rx.value = v ?? false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Built privately. Location is removed from photos. The link works for 24 hours.',
            style: TextStyle(color: p.muted),
          ),
        ],
      );
    });
  }
}

// ------------------------------------------------------- 36 Export ready

/// 36 Export ready: save or share; the link expires in 24 hours.
class ExportReadyView extends StatelessWidget {
  const ExportReadyView({super.key});

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final id = Get.parameters['id'] ?? '';
    final repo = Get.find<VaultRepository>();
    final store = Get.find<VaultStore>();
    final p = context.palette;
    final t = context.textStyles;
    return StreamBuilder<ExportJob?>(
      stream: repo.export(id),
      builder: (context, snap) {
        final job = snap.data;
        final now = DateTime.now();
        final ready = job != null && job.isReady(now) && job.url != null;
        final failed = job?.status == ExportStatus.failed;
        return AppPage(
          showBack: false,
          trailing: null,
          actions: [
            if (ready) ...[
              VaultButton(
                label: kIsWeb ? 'Download' : 'Save to phone',
                icon: Icons.download_rounded,
                onPressed: () => _open(job.url!),
              ),
              VaultButton.secondary(
                label: 'Share with my insurer',
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'My ${job.kind.label.toLowerCase()} from Home Vault. '
                        'This link works until ${Formatters.expiry(job.expiresAt!, now)}:\n${job.url}',
                    subject: 'Home inventory',
                  ),
                ),
              ),
            ] else
              VaultButton.secondary(label: 'Done', onPressed: Get.back),
          ],
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: Get.back,
                child: const Text('Done', style: TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job?.kind.label ?? 'Your list', style: t.titleMedium),
                    Text(
                      '${store.profile.value?.displayName ?? ''} · ${Formatters.medium(now)}',
                      style: TextStyle(color: p.muted, fontSize: 13),
                    ),
                    const Divider(height: 24),
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: p.tonal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(height: 8, color: p.outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              liveRegion: true,
              child: Text(
                failed
                    ? "That list couldn't be built"
                    : ready
                    ? 'Your list is ready'
                    : 'Building your list…',
                textAlign: TextAlign.center,
                style: t.headlineMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (job != null && ready)
              Text(
                [
                  '${job.kind.label} · ${job.format.label}',
                  if (job.itemCount != null)
                    Formatters.count(job.itemCount!, 'item'),
                  if (job.roomCount != null && job.kind == ExportKind.inventory)
                    Formatters.count(job.roomCount!, 'room'),
                ].join(' · '),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, fontSize: 16),
              ),
            if (job?.sizeBytes != null)
              Text(
                '${Formatters.fileSize(job!.sizeBytes!)} · location removed from photos',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, fontSize: 16),
              ),
            if (failed)
              Text(
                job!.error ?? 'Try again in a minute.',
                textAlign: TextAlign.center,
              ),
            if (!ready && !failed)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (ready) ...[
              const SizedBox(height: 18),
              Center(
                child: Pill(
                  'Download link works for 24 hours',
                  tone: PillTone.amber,
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------- 37 Settings

/// 37 Settings: reminders, privacy, account.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = Get.find<VaultStore>();
    final repo = Get.find<VaultRepository>();
    final auth = Get.find<AuthRepository>();
    final notifications = Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : null;
    final p = context.palette;
    Future<void> set(String key, Object value) async {
      try {
        await repo.updateProfile({key: value});
      } catch (_) {
        Toast.show('That setting did not save.');
      }
    }

    return Obx(() {
      final profile = store.profile.value ?? UserProfile(uid: store.uid ?? '');
      final granted = notifications?.granted ?? false;
      return AppPage(
        title: 'Settings',
        children: [
          const SectionLabel('Reminders'),
          if (notifications != null && !granted)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoNote(
                'Notifications are off for Home Vault, so reminders cannot reach '
                'you. Tap to turn them on.',
                icon: Icons.notifications_off_outlined,
                warning: true,
                onTap: () async {
                  final ok = await notifications.requestPermission();
                  if (!ok) {
                    Toast.show(
                      'Open your phone Settings › Notifications › Home Vault to allow them.',
                    );
                  }
                },
              ),
            ),
          ListCard(
            children: [
              SwitchListTile(
                title: const Text(
                  'Warranty reminders',
                  style: TextStyle(fontSize: 17),
                ),
                value: profile.warrantyReminders,
                onChanged: (v) => set('warrantyReminders', v),
              ),
              SwitchListTile(
                title: const Text(
                  'Return deadline reminders',
                  style: TextStyle(fontSize: 17),
                ),
                value: profile.returnReminders,
                onChanged: (v) => set('returnReminders', v),
              ),
              DetailRow(
                'Reminder time',
                MaterialLocalizations.of(context).formatTimeOfDay(
                  TimeOfDay(
                    hour: profile.reminderMinutes ~/ 60,
                    minute: profile.reminderMinutes % 60,
                  ),
                ),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: profile.reminderMinutes ~/ 60,
                      minute: profile.reminderMinutes % 60,
                    ),
                  );
                  if (t != null) {
                    await set('reminderMinutes', t.hour * 60 + t.minute);
                  }
                },
              ),
            ],
          ),
          const SectionLabel('Privacy'),
          ListCard(
            children: [
              SwitchListTile(
                title: const Text(
                  'Keep photo location',
                  style: TextStyle(fontSize: 17),
                ),
                subtitle: const Text('Off: location is removed before upload.'),
                value: profile.keepPhotoLocation,
                onChanged: (v) => set('keepPhotoLocation', v),
              ),
              DetailRow(
                'Privacy policy',
                '',
                onTap: () => Get.toNamed(Routes.privacy),
              ),
              DetailRow(
                'Download all my data',
                '',
                onTap: () =>
                    Get.toNamed(Routes.export, arguments: ExportKind.archive),
              ),
            ],
          ),
          const SectionLabel('Account'),
          ListCard(
            children: [
              DetailRow(
                'Sign-in methods',
                auth.providerSummary.isEmpty ? '—' : auth.providerSummary,
              ),
              DetailRow(
                'Main currency',
                profile.mainCurrency,
                onTap: () async {
                  final c = await Pickers.currency(
                    context,
                    profile.mainCurrency,
                  );
                  if (c != null) await set('mainCurrency', c);
                },
              ),
              if (Get.isRegistered<ReceiptSaver>() &&
                  Get.find<ReceiptSaver>().pending.isNotEmpty)
                DetailRow(
                  'Waiting to save',
                  Formatters.count(
                    Get.find<ReceiptSaver>().pending.length,
                    'receipt',
                  ),
                  onTap: () => Get.toNamed(Routes.pending),
                ),
              DetailRow(
                'Sign out',
                '',
                onTap: () async {
                  final ok = await Pickers.confirm(
                    context,
                    title: 'Sign out?',
                    message:
                        'Drafts not yet saved stay on this phone for when you sign back in.',
                    action: 'Sign out',
                  );
                  if (!ok) return;
                  await auth.signOut();
                  await Get.offAllNamed(Routes.welcome);
                },
              ),
              InkWell(
                onTap: () => Get.toNamed(Routes.deleteAccount),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Delete account',
                    style: TextStyle(color: p.dangerInk, fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('Home Vault 1.0.0', style: TextStyle(color: p.muted)),
          ),
        ],
      );
    });
  }
}

// ---------------------------------------------------- 38 Delete account

class DeleteAccountController extends GetxController {
  DeleteAccountController(this.store, this.auth, this.repo);

  final VaultStore store;
  final AuthRepository auth;
  final VaultRepository repo;
  final busy = false.obs;
  final error = RxnString();

  /// Re-authenticate, then a Function deletes Firestore data, Storage
  /// files, exports and the sign-in.
  Future<void> delete(BuildContext context) async {
    final ok = await Pickers.confirm(
      context,
      title: 'Delete everything?',
      message:
          'This cannot be undone. You will be asked to sign in again to confirm.',
      action: 'Delete my account',
      destructive: true,
    );
    if (!ok) return;
    busy.value = true;
    error.value = null;
    try {
      await auth.reauthenticate();
      await repo.deleteAccount();
      if (Get.isRegistered<ReceiptSaver>()) {
        for (final d in [...Get.find<ReceiptSaver>().pending]) {
          await Get.find<ReceiptSaver>().discard(d);
        }
      }
      await auth.signOut();
      await Get.offAllNamed(kIsWeb ? Routes.webSignIn : Routes.welcome);
      Toast.show('Your account and data have been deleted.');
    } on AuthFailure catch (e) {
      error.value = e.message.isEmpty ? null : e.message;
    } catch (e) {
      error.value = '$e';
    } finally {
      busy.value = false;
    }
  }
}

/// 38 Delete account: explains what is deleted, then confirms.
class DeleteAccountView extends GetView<DeleteAccountController> {
  const DeleteAccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.textStyles;
    return Obx(() {
      final store = controller.store;
      return AppPage(
        titleInHeader: false,
        actions: [
          VaultButton.danger(
            label: 'Delete my account',
            loading: controller.busy.value,
            onPressed: () => controller.delete(context),
          ),
          VaultButton.secondary(label: 'Keep my account', onPressed: Get.back),
        ],
        children: [
          IconTile(
            Icons.delete_outline_rounded,
            size: 72,
            color: p.dangerSurface,
            iconColor: p.dangerInk,
          ),
          const SizedBox(height: 20),
          Text('Delete your account?', style: t.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'This permanently deletes, from the app and the website:',
            style: t.bodyLarge?.copyWith(color: p.muted),
          ),
          const SizedBox(height: 16),
          VaultCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in [
                  '${Formatters.count(store.receipts.length, 'receipt')} and their originals',
                  '${Formatters.count(store.items.length, 'item')}, photos and room videos',
                  'Warranties, reminders and downloads',
                  'Your sign-in',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      '·  $line',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InfoNote(
            'Download a copy of everything first',
            icon: Icons.download_rounded,
            onTap: () => Get.toNamed(
              kIsWeb ? Routes.webDownloads : Routes.export,
              arguments: ExportKind.archive,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Backups are cleared within 30 days. You'll be asked to sign in again to confirm.",
            style: TextStyle(color: p.muted),
          ),
          if (controller.error.value != null) ...[
            const SizedBox(height: 14),
            InfoNote(
              controller.error.value!,
              warning: true,
              icon: Icons.error_outline,
            ),
          ],
        ],
      );
    });
  }
}

// ------------------------------------------------- Pending drafts (merged)

/// Receipts confirmed on this phone but not yet saved on the server.
class PendingView extends StatelessWidget {
  const PendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final saver = Get.find<ReceiptSaver>();
    final p = context.palette;
    return Obx(
      () => AppPage(
        title: 'Waiting to save',
        subtitle:
            'These are kept on this phone and save automatically when '
            'you are online. Nothing here is saved yet.',
        actions: [
          if (saver.pending.isNotEmpty)
            VaultButton(label: 'Try again now', onPressed: saver.retryPending),
        ],
        children: [
          if (saver.pending.isEmpty)
            const EmptyState(
              icon: Icons.cloud_done_outlined,
              title: 'All saved',
              message: 'Nothing is waiting.',
            ),
          for (final ReceiptDraft d in saver.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VaultCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.shop ?? 'Receipt',
                      style: context.textStyles.titleMedium,
                    ),
                    Text(
                      [
                        Formatters.mediumOrNotStated(d.purchaseDate),
                        if (d.totalMinor != null)
                          Money.format(d.totalMinor!, currency: d.currency),
                        Formatters.count(d.items.length, 'item'),
                      ].join(' · '),
                      style: TextStyle(color: p.muted),
                    ),
                    if (d.lastError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          d.lastError!,
                          style: TextStyle(color: p.warningInk),
                        ),
                      ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            CaptureFlow.resume(d..state = DraftState.editing);
                            Get.toNamed(Routes.reviewDetails);
                          },
                          child: const Text('Check again'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ok = await Pickers.confirm(
                              context,
                              title: 'Discard this receipt?',
                              message:
                                  'It has not been saved, so it will be lost.',
                              action: 'Discard',
                              destructive: true,
                            );
                            if (ok) await saver.discard(d);
                          },
                          child: Text(
                            'Discard',
                            style: TextStyle(color: p.dangerInk),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- Help

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const faqs = [
      (
        'Is my receipt read by a server?',
        'No. Text is read on your phone. The original is stored privately and '
            'opens only when you tap View receipt.',
      ),
      (
        'Why does it say "Not stated"?',
        "We never guess. If a value isn't on the receipt, or we couldn't read "
            'it, it stays Not stated until you add it.',
      ),
      (
        'Are my items insured or protected?',
        'Home Vault keeps your records and photos. Your insurer decides what is '
            'covered and what evidence it accepts.',
      ),
      (
        'What happens offline?',
        'You can capture and check receipts offline. They show "Waiting for '
            'connection" and save by themselves when you are back online.',
      ),
      (
        'How do I get my data out?',
        'Account › Download lists. Downloads, viewing and deleting are always free.',
      ),
      (
        'Can I use it on a computer?',
        'Yes — sign in on the website with the same account to view items and '
            'download your lists.',
      ),
    ];
    return AppPage(
      title: 'Help',
      children: [
        for (final (q, a) in faqs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VaultCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                title: Text(q, style: context.textStyles.titleMedium),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  Text(a, style: TextStyle(color: p.muted, fontSize: 16)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        VaultButton.secondary(
          label: 'Email support',
          icon: Icons.mail_outline_rounded,
          onPressed: () => launchUrl(
            Uri.parse(
              'mailto:support@homevault.example?subject=Home%20Vault%20help',
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------- Legal pages

class LegalView extends StatelessWidget {
  const LegalView({super.key, required this.terms});

  final bool terms;

  @override
  Widget build(BuildContext context) {
    final sections = terms ? _terms : _privacy;
    return AppPage(
      title: terms ? 'Terms of use' : 'Privacy policy',
      children: [
        for (final (h, body) in sections) ...[
          Text(h, style: context.textStyles.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  static const _privacy = [
    (
      'What we collect',
      'Your sign-in (Apple, Google or email), the receipts, items, rooms, '
          'photos and videos you add, and the reminder settings you choose. '
          'Crash reports contain no receipt text, images or tokens.',
    ),
    (
      'Why',
      'Only to keep your records, show them to you on the app and website, '
          'send the reminders you set, and build the lists you ask for. No '
          'marketing and no selling of data.',
    ),
    (
      'Where it is stored',
      'Google Firebase in the UK/EU (europe-west2, London). Data is encrypted '
          'in transit and at rest. It is not end-to-end encrypted: Google '
          'servers and our Cloud Functions can process it to provide the service.',
    ),
    (
      'Your photos',
      'Location is removed from photos before upload unless you turn on '
          '"Keep photo location", and always from downloads.',
    ),
    (
      'Your rights (UK GDPR)',
      'View, download and delete your data at any time, free, from Account. '
          'Deleting your account removes your data, files and sign-in; backups '
          'are cleared within 30 days.',
    ),
  ];

  static const _terms = [
    (
      'What Home Vault does',
      'It stores records you confirm. It never says an item is verified, '
          'protected or insured; your insurer decides what it accepts.',
    ),
    (
      'Your content',
      'You own everything you add. We use it only to run the service for you.',
    ),
    (
      'Always free',
      'Viewing, exporting and deleting your data are always free.',
    ),
  ];
}
