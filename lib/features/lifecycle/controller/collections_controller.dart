import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 93 · Collections and 94 · Appraisal.
class CollectionsController extends GetxController {
  CollectionsController({required this._ownership});

  final OwnershipRepository _ownership;

  final formKey = GlobalKey<FormState>();
  final appraiserController = TextEditingController();
  final valueController = TextEditingController();
  final appraisalItem = RxnString();
  final appraisalDate = Rxn<DateTime>();
  final certificateAttached = false.obs;

  List<String> get collections => _ownership.collections;

  List<Possession> itemsIn(String collection) =>
      _ownership.inCollection(collection);

  List<Appraisal> get appraisals => _ownership.appraisals;

  bool isStale(Appraisal a) =>
      a.date.isBefore(Dates.addMonths(_ownership.today, -24));

  Future<void> create(BuildContext context) async {
    final name = await promptText(
      context,
      title: 'Create collection',
      label: 'Name',
    );
    if (name == null || name.isEmpty) return;
    if (collections.any((c) => c.toLowerCase() == name.toLowerCase())) {
      Toast.show('$name already exists');
      return;
    }
    _ownership.addCollection(name);
  }

  void openItem(Possession p) =>
      Get.toNamed(Routes.possessionDetail, arguments: p.id);

  Future<void> pickItem(BuildContext context) async {
    final names = [for (final p in _ownership.possessions) p.name];
    final i = await showOptionSheet(context, title: 'Item', options: names);
    if (i != null) appraisalItem.value = names[i];
  }

  Future<void> pickAppraisalDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: appraisalDate.value ?? _ownership.today,
      last: _ownership.today,
    );
    if (picked != null) appraisalDate.value = picked;
  }

  void saveAppraisal() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (appraisalItem.value == null) {
      Toast.show('Choose the item first');
      return;
    }
    _ownership.appraisals.add(
      Appraisal(
        item: appraisalItem.value!,
        appraiser: appraiserController.text.trim(),
        value: Money.parse(valueController.text)!,
        date: appraisalDate.value ?? _ownership.today,
      ),
    );
    appraiserController.clear();
    valueController.clear();
    appraisalItem.value = null;
    certificateAttached.value = false;
    Toast.show('Appraisal saved');
  }

  @override
  void onClose() {
    appraiserController.dispose();
    valueController.dispose();
    super.onClose();
  }
}
