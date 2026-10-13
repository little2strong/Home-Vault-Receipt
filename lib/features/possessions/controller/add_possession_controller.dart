import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 54 · Add possession → 55 · Product identification → 56 · Serial number.
class AddPossessionController extends GetxController {
  AddPossessionController({required this._ownership, String? room})
    : room = (room ?? _ownership.rooms.first).obs;

  final OwnershipRepository _ownership;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final priceController = TextEditingController();
  final serialController = TextEditingController();
  final modelController = TextEditingController();
  final Rx<String> room;
  final condition = ItemCondition.good.obs;
  final labelPhotographed = false.obs;
  final created = Rxn<Possession>();

  List<String> get rooms => _ownership.rooms;

  Future<void> pickRoom(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Room',
      options: rooms,
      selected: rooms.indexOf(room.value),
    );
    if (i != null) room.value = rooms[i];
  }

  Future<void> pickCondition(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Condition',
      options: [for (final c in ItemCondition.values) c.label],
      selected: condition.value.index,
    );
    if (i != null) condition.value = ItemCondition.values[i];
  }

  void save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final brand = brandController.text.trim();
    final possession = Possession(
      id: Ids.next('p'),
      name: nameController.text.trim(),
      room: room.value,
      brandModel: brand.isEmpty ? null : brand,
      purchasePrice: Money.parse(priceController.text),
      condition: condition.value,
      events: const [
        OwnershipEvent(label: 'Today', title: 'Added to inventory'),
      ],
    );
    _ownership.addPossession(possession);
    created.value = possession;
    Get.toNamed(Routes.productIdentification);
  }

  // 55 · Product identification -------------------------------------------

  /// A naive on-device suggestion from the typed name; the user confirms.
  String get suggestedProduct {
    final p = created.value;
    if (p == null) return '';
    return p.brandModel == null ? p.name : '${p.brandModel} ${p.name}';
  }

  void confirmProduct() => Get.toNamed(Routes.serialNumber);

  // 56 · Serial number ----------------------------------------------------

  void readLabel() {
    serialController.text =
        'C02-SAMPLE-${1000 + _ownership.possessions.length}';
    labelPhotographed.value = true;
  }

  /// Another possession already using this serial number.
  Possession? get serialClash {
    final serial = serialController.text.trim().toLowerCase();
    if (serial.isEmpty) return null;
    return _ownership.possessions.firstWhereOrNull(
      (p) =>
          p.id != created.value?.id && p.serialNumber?.toLowerCase() == serial,
    );
  }

  void confirmSerial() {
    final p = created.value;
    if (p == null) return;
    final serial = serialController.text.trim();
    if (serial.isEmpty) {
      Toast.show('Enter the serial number, or skip this step.');
      return;
    }
    final model = modelController.text.trim();
    _ownership.updatePossession(
      p.copyWith(
        serialNumber: serial,
        modelNumber: model.isEmpty ? null : model,
        photos: labelPhotographed.value ? [...p.photos, 'Serial label'] : null,
      ),
    );
    finish();
  }

  void finish() {
    final id = created.value?.id;
    Get.until(
      (route) => route.settings.name == Routes.addPossession || route.isFirst,
    );
    Get.back();
    if (id != null) Get.toNamed(Routes.possessionDetail, arguments: id);
  }

  @override
  void onClose() {
    nameController.dispose();
    brandController.dispose();
    priceController.dispose();
    serialController.dispose();
    modelController.dispose();
    super.onClose();
  }
}
