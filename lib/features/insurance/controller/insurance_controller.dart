import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/models/ownership_models.dart';
import '../../../core/models/product_category.dart';
import '../../../core/repositories/ownership_repository.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 75 · Readiness, 76 · Report, 77 · New claim, 78 · Workspace,
/// 79 · Package, 80 · Valuation.
class InsuranceController extends GetxController {
  InsuranceController({required this._ownership});

  /// Items above this value deserve photo evidence (minor units).
  static const highValue = 50000;

  /// Appraisals older than this are flagged as out of date.
  static const appraisalMaxAgeMonths = 24;

  static const incidentTypes = [
    'Accidental damage',
    'Theft',
    'Water damage',
    'Fire',
    'Loss',
  ];

  final OwnershipRepository _ownership;

  // 76 · report options
  final scope = 'Main home · all rooms'.obs;
  final valueBasis = 'Recorded purchase values'.obs;

  // 77 · claim form
  final incidentType = incidentTypes.first.obs;
  final incidentDate = Rxn<DateTime>();
  final affectedItem = RxnString();
  final notesController = TextEditingController();

  List<Possession> get owned => _ownership.possessions
      .where((p) => p.status == OwnershipStatus.owned)
      .toList();

  int get completeness => _ownership.completenessPercent();

  int get highValueMissingPhotos => owned
      .where((p) => (p.purchasePrice ?? 0) >= highValue && !p.hasPhoto)
      .length;

  int get missingSerials => owned.where((p) => !p.hasSerial).length;

  int get staleAppraisals => _ownership.appraisals
      .where(
        (a) => a.date.isBefore(
          Dates.addMonths(_ownership.today, -appraisalMaxAgeMonths),
        ),
      )
      .length;

  int get recordedTotal => _ownership.recordedValue(owned);

  ClaimDraft? get claim => _ownership.claims.lastOrNull;

  void reviewGaps() => Get.toNamed(Routes.completeness);

  void openReport() => Get.toNamed(Routes.insuranceReport);

  void openClaim() {
    incidentType.value = incidentTypes.first;
    incidentDate.value = _ownership.today;
    affectedItem.value = null;
    notesController.clear();
    Get.toNamed(Routes.newClaim);
  }

  void openValuation() => Get.toNamed(Routes.valuation);

  Future<void> pickScope(BuildContext context) async {
    final options = ['Main home · all rooms', ..._ownership.rooms];
    final i = await showOptionSheet(
      context,
      title: 'Scope',
      options: options,
      selected: options.indexOf(scope.value),
    );
    if (i != null) scope.value = options[i];
  }

  Future<void> pickValueBasis(BuildContext context) async {
    const options = ['Recorded purchase values', 'Replacement estimates'];
    final i = await showOptionSheet(
      context,
      title: 'Value basis',
      options: options,
      selected: options.indexOf(valueBasis.value),
    );
    if (i != null) valueBasis.value = options[i];
  }

  List<Possession> get reportItems => scope.value.startsWith('Main home')
      ? owned
      : owned.where((p) => p.room == scope.value).toList();

  int get reportValue {
    final items = reportItems;
    return valueBasis.value.startsWith('Replacement')
        ? items.fold(0, (s, p) => s + replacementEstimate(p))
        : _ownership.recordedValue(items);
  }

  Future<void> pickIncidentType(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Incident type',
      options: incidentTypes,
      selected: incidentTypes.indexOf(incidentType.value),
    );
    if (i != null) incidentType.value = incidentTypes[i];
  }

  Future<void> pickIncidentDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: incidentDate.value ?? _ownership.today,
      last: _ownership.today,
    );
    if (picked != null) incidentDate.value = picked;
  }

  Future<void> pickAffectedItem(BuildContext context) async {
    final names = [for (final p in owned) p.name];
    final i = await showOptionSheet(
      context,
      title: 'Affected items',
      options: names,
      selected: affectedItem.value == null
          ? null
          : names.indexOf(affectedItem.value!),
    );
    if (i != null) affectedItem.value = names[i];
  }

  void createWorkspace() {
    if (affectedItem.value == null) {
      Toast.show('Choose the affected item');
      return;
    }
    _ownership.claims.add(
      ClaimDraft(
        incidentType: incidentType.value,
        incidentDate: incidentDate.value ?? _ownership.today,
        item: affectedItem.value!,
        notes: notesController.text.trim(),
      ),
    );
    Get.offNamed(Routes.claimWorkspace);
  }

  Possession? get claimItem {
    final name = claim?.item;
    return name == null ? null : owned.firstWhereOrNull((p) => p.name == name);
  }

  void openPackage() => Get.toNamed(Routes.claimPackage);

  void generatePackage() {
    Toast.show(
      'Claim package prepared. Review it before sending to an insurer.',
    );
    Get.until(
      (route) =>
          route.settings.name == Routes.insuranceReadiness || route.isFirst,
    );
  }

  // 80 · Valuation (indicative only) ---------------------------------------

  double _years(Possession p) {
    final bought = p.purchaseDate;
    // Missing dates are unknown, not "a year old". Inventing a year would
    // depreciate and inflate replacement cost with no evidence.
    if (bought == null) return 0;
    return math.max(0, Dates.daysBetween(bought, _ownership.today) / 365);
  }

  /// Straight-line depreciation by category, floored at 20%.
  int currentEstimate(Possession p) {
    final rate = switch (p.category) {
      ProductCategory.electronics => 0.25,
      ProductCategory.appliances => 0.15,
      ProductCategory.home => 0.10,
      _ => 0.10,
    };
    final factor = math.max(0.2, 1 - rate * _years(p));
    return ((p.purchasePrice ?? 0) * factor).round();
  }

  /// Purchase price grown by 4% a year as a rough replacement cost.
  int replacementEstimate(Possession p) =>
      ((p.purchasePrice ?? 0) * math.pow(1.04, _years(p))).round();

  Map<ProductCategory, int> get valueByCategory {
    final totals = <ProductCategory, int>{};
    for (final p in owned) {
      totals[p.category] = (totals[p.category] ?? 0) + (p.purchasePrice ?? 0);
    }
    return Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  String money(int minor) => Money.formatWhole(minor);

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
