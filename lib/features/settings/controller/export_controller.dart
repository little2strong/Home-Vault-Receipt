import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/services/export_service.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

/// 48 · Export selection and 49 · Export ready.
class ExportController extends GetxController {
  ExportController({
    required this._receipts,
    required this._exporter,
    this._clock = DateTime.now,
  });

  final ReceiptRepository _receipts;
  final ExportService _exporter;
  final Clock _clock;

  final request = const ExportRequest().obs;
  final archive = Rxn<ExportArchive>();

  int get selectedCount =>
      _exporter.select(_receipts.saved, request.value.scope, _clock()).length;

  String get recordsLabel {
    final scope = request.value.scope;
    final count = Formatters.count(selectedCount, 'receipt');
    return scope == ExportScope.all ? 'All $count' : '${scope.label} · $count';
  }

  String get expiresLabel {
    final a = archive.value;
    return a == null ? '' : Formatters.expiry(a.expiresAt, _clock());
  }

  Future<void> pickScope(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Records',
      options: [for (final s in ExportScope.values) s.label],
      selected: request.value.scope.index,
    );
    if (i != null) {
      request.value = request.value.copyWith(scope: ExportScope.values[i]);
    }
  }

  Future<void> pickFormat(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Data format',
      options: [for (final f in ExportFormat.values) f.label],
      selected: request.value.format.index,
    );
    if (i != null) {
      request.value = request.value.copyWith(format: ExportFormat.values[i]);
    }
  }

  Future<void> pickOriginals(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Original documents',
      options: const ['Include', 'Leave out'],
      selected: request.value.includeOriginals ? 0 : 1,
    );
    if (i != null) {
      request.value = request.value.copyWith(includeOriginals: i == 0);
    }
  }

  Future<void> pickExpiry(BuildContext context) async {
    final i = await showOptionSheet(
      context,
      title: 'Link expiry',
      options: [for (final e in LinkExpiry.values) e.label],
      selected: request.value.expiry.index,
    );
    if (i != null) {
      request.value = request.value.copyWith(expiry: LinkExpiry.values[i]);
    }
  }

  void createExport() {
    if (selectedCount == 0) {
      Toast.show('There are no saved receipts in this range.');
      return;
    }
    archive.value = _exporter.build(_receipts.saved, request.value, _clock());
    Get.toNamed(Routes.exportReady);
  }

  Future<void> copyCsv() => _copy(archive.value?.csv, 'CSV');

  Future<void> copyJson() => _copy(archive.value?.json, 'JSON');

  Future<void> _copy(String? data, String label) async {
    if (data == null) return;
    await Clipboard.setData(ClipboardData(text: data));
    Toast.show('$label copied. Paste it somewhere private.');
  }
}
