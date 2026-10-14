import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/vault_repository.dart';
import '../../../core/data/vault_store.dart';
import '../../../core/models/item.dart';
import '../../../core/models/vault_models.dart';
import '../../../core/services/capture_service.dart';
import '../../../core/services/image_tools.dart';
import '../../../core/theme/vault_palette.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/vault_ui.dart';
import '../../start/controller/start_controllers.dart';

class EditWarrantyController extends GetxController {
  EditWarrantyController(this.store, this.repo);

  final VaultStore store;
  final VaultRepository repo;
  late final String itemId = Get.parameters['id'] ?? '';
  late final Warranty? existing = store.warrantyFor(itemId);

  final byLength = true.obs;
  final length = TextEditingController();
  final years = true.obs;
  final start = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final remind3 = true.obs;
  final remind2 = true.obs;
  final cardPath = RxnString();
  final saving = false.obs;
  final tick = 0.obs;

  Item? get item => store.item(itemId);

  @override
  void onInit() {
    super.onInit();
    start.value = item?.purchaseDate;
    final w = existing;
    if (w != null) {
      endDate.value = w.endDate;
      remind3.value = w.remindMonthsBefore;
      remind2.value = w.remindWeeksBefore;
      cardPath.value = w.cardPhotoPath;
      if (w.lengthMonths != null && start.value != null) {
        final m = w.lengthMonths!;
        years.value = m % 12 == 0;
        length.text = '${years.value ? m ~/ 12 : m}';
      } else {
        byLength.value = false;
      }
    } else {
      byLength.value = start.value != null;
      length.text = '1';
    }
    if (start.value == null) byLength.value = false;
  }

  int? get months {
    final n = int.tryParse(length.text.trim());
    if (n == null || n <= 0) return null;
    return years.value ? n * 12 : n;
  }

  /// The end date the user confirms, from a length or typed directly.
  DateTime? get end {
    tick.value;
    if (byLength.value) {
      final m = months;
      final s = start.value;
      return m == null || s == null ? null : Dates.addMonths(s, m);
    }
    return endDate.value;
  }

  Future<void> pickEnd(BuildContext context) async {
    final d = await Pickers.date(
      context,
      initial: endDate.value ?? Dates.addMonths(DateTime.now(), 12),
      first: DateTime(2000),
      help: 'Warranty end date',
    );
    if (d != null) endDate.value = d;
  }

  Future<void> cardPhoto() async {
    final x = await Get.find<CaptureService>().pickItemPhoto(camera: true);
    if (x == null) return;
    try {
      final jpeg = await ImageTools.compressForUpload(await x.readAsBytes());
      cardPath.value = await repo.uploadWarrantyCard(itemId, jpeg);
      Toast.show('Warranty card photo added');
    } catch (_) {
      Toast.show("The photo didn't upload. Try again.");
    }
  }

  Future<void> addToCalendar() async {
    final e = end;
    if (e == null) return;
    await Add2Calendar.addEvent2Cal(
      Event(
        title: 'Warranty ends: ${item?.name ?? 'item'}',
        description:
            'Home Vault reminder. Check the terms with the shop or maker.',
        startDate: e,
        endDate: e.add(const Duration(hours: 1)),
        allDay: true,
      ),
    );
  }

  Future<void> save() async {
    final e = end;
    final i = item;
    if (e == null || i == null) {
      Toast.show('Add the length or the end date.');
      return;
    }
    saving.value = true;
    try {
      await repo.saveWarranty(
        itemId: itemId,
        endDate: e,
        lengthMonths: byLength.value ? months : null,
        itemName: i.name,
        shop: i.shop,
        purchaseDate: i.purchaseDate,
        remind3Months: remind3.value,
        remind2Weeks: remind2.value,
        cardPhotoPath: cardPath.value,
      );
      if (remind3.value || remind2.value) await askForRemindersOnce();
      Get.back<void>();
      Toast.show('Warranty saved');
    } catch (_) {
      Toast.show('The warranty did not save. Try again.');
    } finally {
      saving.value = false;
    }
  }

  Future<void> remove(BuildContext context) async {
    final ok = await Pickers.confirm(
      context,
      title: 'Remove this warranty?',
      message: 'Its reminders stop too.',
      action: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    await repo.deleteWarranty(itemId);
    Get.back<void>();
  }

  @override
  void onClose() {
    length.dispose();
    super.onClose();
  }
}

/// 31 Edit warranty: end date or length, card photo, reminders.
class EditWarrantyView extends GetView<EditWarrantyController> {
  const EditWarrantyView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Obx(() {
      final end = controller.end;
      final hasStart = controller.start.value != null;
      return AppPage(
        eyebrow: controller.item?.name,
        title: 'Warranty',
        actions: [
          VaultButton(
            label: 'Save warranty',
            loading: controller.saving.value,
            onPressed: end == null ? null : controller.save,
          ),
        ],
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.tonal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (byLength, label) in [
                  (true, 'Length'),
                  (false, 'End date'),
                ])
                  Expanded(
                    child: Semantics(
                      selected: controller.byLength.value == byLength,
                      button: true,
                      child: InkWell(
                        onTap: () {
                          if (byLength && !hasStart) {
                            Toast.show(
                              'The purchase date is not stated, so pick the end date.',
                            );
                            return;
                          }
                          controller.byLength.value = byLength;
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: controller.byLength.value == byLength
                                ? p.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (controller.byLength.value)
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Length',
                    controller: controller.length,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => controller.tick.value++,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: PickerField(
                    label: 'Unit',
                    value: controller.years.value ? 'Years' : 'Months',
                    onTap: () => controller.years.toggle(),
                  ),
                ),
              ],
            )
          else
            PickerField(
              label: 'End date',
              value: controller.endDate.value == null
                  ? null
                  : Formatters.medium(controller.endDate.value!),
              placeholder: 'Choose the end date',
              icon: Icons.calendar_today_outlined,
              onTap: () => controller.pickEnd(context),
            ),
          const SizedBox(height: 18),
          if (end != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.tonal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.byLength.value
                        ? 'From purchase on ${Formatters.medium(controller.start.value!)}, it ends'
                        : 'It ends',
                    style: TextStyle(
                      color: p.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatters.medium(end),
                    style: context.textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const FieldLabel('Remind me'),
          VaultCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                CheckboxListTile(
                  value: controller.remind3.value,
                  onChanged: (v) => controller.remind3.value = v ?? false,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '3 months before'
                    '${end == null ? '' : ' · ${Formatters.medium(Warranty.threeMonthsBefore(end))}'}',
                  ),
                ),
                const Divider(height: 1),
                CheckboxListTile(
                  value: controller.remind2.value,
                  onChanged: (v) => controller.remind2.value = v ?? false,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '2 weeks before'
                    '${end == null ? '' : ' · ${Formatters.medium(Warranty.twoWeeksBefore(end))}'}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.cardPhoto,
              icon: Icon(
                controller.cardPath.value == null
                    ? Icons.photo_camera_outlined
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                controller.cardPath.value == null
                    ? 'Add a photo of the warranty card'
                    : 'Warranty card photo added · replace',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: end == null ? null : controller.addToCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text(
                'Add end date to my calendar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (controller.existing != null)
            Align(
              alignment: Alignment.centerLeft,
              child: LinkButton(
                label: 'Remove this warranty',
                color: p.dangerInk,
                onPressed: () => controller.remove(context),
              ),
            ),
        ],
      );
    });
  }
}
