import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 69 · Warranties, 70 · Warranty assistant, 71 · Maintenance,
/// 72 · Maintenance record, 73 · Repair record, 74 · Recall alert.
class ProtectionController extends GetxController {
  ProtectionController({required this._ownership});

  final OwnershipRepository _ownership;

  // Shared form state for 72 and 73.
  final formKey = GlobalKey<FormState>();
  final workController = TextEditingController();
  final costController = TextEditingController();
  final providerController = TextEditingController();
  final item = RxnString();
  final date = Rxn<DateTime>();
  final nextService = Rxn<DateTime>();

  DateTime get today => _ownership.today;

  /// Items with a confirmed warranty or missing terms, soonest expiry first.
  List<Possession> get warranties {
    final list = _ownership.possessions
        .where((p) => p.warrantyExpiry != null || p.warrantyTermsMissing)
        .toList();
    list.sort((a, b) {
      final aDate = a.warrantyExpiry;
      final bDate = b.warrantyExpiry;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return list;
  }

  List<MaintenanceTask> get maintenance => _ownership.maintenance;

  /// Open tasks, plus completed work that already has a future next service.
  List<MaintenanceTask> get upcoming {
    final tasks = [
      for (final m in maintenance)
        if (_isUpcoming(m)) m,
    ];
    tasks.sort((a, b) => _shownDue(a).compareTo(_shownDue(b)));
    return tasks;
  }

  /// Work that was logged, newest first. Scheduling a next service does not
  /// drop the date the work was actually done.
  List<MaintenanceTask> get history {
    final done = maintenance.where((m) => m.done).toList();
    done.sort((a, b) => b.due.compareTo(a.due));
    return done;
  }

  DateTime _shownDue(MaintenanceTask m) =>
      m.done && m.nextDue != null ? m.nextDue! : m.due;

  bool _isUpcoming(MaintenanceTask m) {
    if (m.nextDue != null && !Dates.dateOnly(m.nextDue!).isBefore(today)) {
      return true;
    }
    return !m.done && !Dates.dateOnly(m.due).isBefore(today);
  }

  List<RepairRecord> get repairs => _ownership.repairs;

  List<String> get itemNames => {
    for (final p in _ownership.possessions) p.name,
    for (final m in _ownership.maintenance) m.item,
  }.toList();

  Possession? possession(String id) => _ownership.byId(id);

  void openWarranty(Possession p) =>
      Get.toNamed(Routes.warrantyAssistant, arguments: p.id);

  void openDocuments(String id) =>
      Get.toNamed(Routes.itemDocuments, arguments: id);

  void openReceipt(Possession p) {
    if (p.receiptId == null) {
      Toast.show('No receipt linked yet');
      return;
    }
    Get.toNamed(Routes.receiptDetail, arguments: p.receiptId);
  }

  void _resetForm() {
    workController.clear();
    costController.clear();
    providerController.clear();
    item.value = null;
    date.value = today;
    nextService.value = null;
  }

  void newMaintenance() {
    _resetForm();
    Get.toNamed(Routes.maintenanceRecord);
  }

  void newRepair() {
    _resetForm();
    Get.toNamed(Routes.repairRecord);
  }

  Future<void> pickItem(BuildContext context) async {
    final names = itemNames;
    final i = await showOptionSheet(
      context,
      title: 'Item',
      options: names,
      selected: item.value == null ? null : names.indexOf(item.value!),
    );
    if (i != null) item.value = names[i];
  }

  Future<void> pickDateFor(
    BuildContext context,
    Rxn<DateTime> target, {
    bool future = false,
  }) async {
    final picked = await pickDate(
      context,
      initial: target.value ?? today,
      first: future ? today : null,
      last: future ? null : today,
    );
    if (picked != null) target.value = picked;
  }

  bool _validItem() {
    if (item.value != null) return true;
    Toast.show('Choose the item first');
    return false;
  }

  void saveMaintenance() {
    if (!(formKey.currentState?.validate() ?? false) || !_validItem()) return;
    _ownership.addMaintenance(
      MaintenanceTask(
        id: Ids.next('m'),
        item: item.value!,
        work: workController.text.trim(),
        due: date.value ?? today,
        cost: Money.parse(costController.text),
        nextDue: nextService.value,
        done: true,
      ),
    );
    Get.back();
    Toast.show('Maintenance logged');
  }

  void saveRepair() {
    if (!(formKey.currentState?.validate() ?? false) || !_validItem()) return;
    _ownership.addRepair(
      RepairRecord(
        id: Ids.next('r'),
        item: item.value!,
        problem: workController.text.trim(),
        provider: providerController.text.trim(),
        cost: Money.parse(costController.text) ?? 0,
        date: date.value ?? today,
      ),
    );
    Get.back();
    Toast.show('Repair saved');
  }

  Future<void> viewOfficialNotice(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Illustrative alert'),
      content: const Text(
        'This is sample data. Real recall alerts will link to the '
        'manufacturer or regulator notice, and always ask you to verify the '
        'serial range yourself.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  void onClose() {
    workController.dispose();
    costController.dispose();
    providerController.dispose();
    super.onClose();
  }
}
