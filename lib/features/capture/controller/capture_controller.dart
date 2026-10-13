import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/models/receipt_extraction.dart';
import '../../../core/models/receipt_model.dart';
import '../../../core/repositories/receipt_repository.dart';
import '../../../core/repositories/settings_repository.dart';
import '../../../core/services/document_service.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/receipt_date_parser.dart';
import '../../../core/utils/toast.dart';
import '../../../core/widgets/pickers.dart';

enum FlashMode {
  auto('Flash: auto'),
  on('Flash: on'),
  off('Flash: off');

  const FlashMode(this.label);

  final String label;
}

/// Owns one capture session, from choosing a source to the OCR hand-off.
/// Registered by the Add source route, which stays under every capture step.
class CaptureController extends GetxController {
  CaptureController({
    required this._documents,
    required this._receipts,
    required this._settings,
    this._clock = DateTime.now,
  });

  final DocumentService _documents;
  final ReceiptRepository _receipts;
  final SettingsRepository _settings;
  final Clock _clock;

  /// Pages of one receipt, in reading order.
  final pages = <SourceDocument>[].obs;
  final pdf = Rxn<SourceDocument>();

  /// The photo just taken, waiting on the crop screen.
  final pendingCapture = Rxn<SourceDocument>();
  final flash = FlashMode.auto.obs;
  final showEdges = false.obs;
  final ocrProgress = 0.0.obs;
  final ocrStage = 0.obs;

  ReceiptSource _source = ReceiptSource.camera;
  Timer? _progressTimer;
  bool _ocrCancelled = false;

  bool get canAddPage => pages.length < DocumentService.maxPhotos;

  // 15 · Add source --------------------------------------------------------

  /// The record's source is how its first page arrived.
  void chooseCamera() {
    if (pages.isEmpty) _source = ReceiptSource.camera;
    Get.toNamed(
      _settings.cameraAllowed.value ? Routes.scanner : Routes.cameraPermission,
    );
  }

  /// Pickers open on the navigator's context, so they still work when the
  /// calling screen has just been popped.
  Future<void> choosePhotos() async {
    final context = Get.context;
    if (context == null) return;
    final photos = _documents.samplePhotos();
    final i = await showOptionSheet(
      context,
      title: 'Choose a photo or screenshot',
      options: [for (final p in photos) p.fileName],
    );
    if (i == null) return;
    if (pages.isEmpty) _source = ReceiptSource.photos;
    _addPage(photos[i]);
    _openPages();
  }

  Future<void> choosePdf() async {
    final context = Get.context;
    if (context == null) return;
    final files = _documents.samplePdfs();
    final i = await showOptionSheet(
      context,
      title: 'Choose a PDF invoice',
      options: [
        for (final f in files)
          '${f.fileName} · ${f.pageCount} '
              '${f.pageCount == 1 ? 'page' : 'pages'}',
      ],
    );
    if (i == null) return;
    final file = files[i];
    _source = ReceiptSource.pdf;
    try {
      _documents.checkPdf(file);
      pdf.value = file;
      Get.toNamed(Routes.pdfImport);
    } on LockedDocumentException {
      Get.toNamed(Routes.pdfBlocked);
    } on AppException catch (e) {
      Toast.show(e.message);
    }
  }

  void chooseManual() => Get.toNamed(Routes.manualReceipt);

  // 16 · Camera permission -------------------------------------------------

  Future<void> allowCamera() async {
    await _settings.allowCamera();
    Get.offNamed(Routes.scanner);
  }

  // 17 · Scanner and 18 · Crop ---------------------------------------------

  void cycleFlash() => flash.value =
      FlashMode.values[(flash.value.index + 1) % FlashMode.values.length];

  void capture() {
    pendingCapture.value = _documents.cameraCapture();
    showEdges.value = false;
    Get.toNamed(Routes.crop);
  }

  void toggleEdges() => showEdges.toggle();

  void usePhoto() {
    final photo = pendingCapture.value;
    if (photo == null) return;
    _addPage(photo);
    pendingCapture.value = null;
    _openPages();
  }

  // 19 · Multi photo -------------------------------------------------------

  String pageNote(int index) {
    if (index == 0) return 'Top of receipt';
    if (index == pages.length - 1) return 'Bottom of receipt';
    return 'Middle of receipt';
  }

  void addAnotherPhoto() {
    if (!canAddPage) {
      Toast.show('Maximum ${DocumentService.maxPhotos} photos per receipt');
      return;
    }
    chooseCamera();
  }

  void movePage(int from, int to) {
    if (to < 0 || to >= pages.length) return;
    final page = pages.removeAt(from);
    pages.insert(to, page);
  }

  void removePage(int index) {
    pages.removeAt(index);
    if (pages.isEmpty) Get.back();
  }

  // 22 · OCR processing ----------------------------------------------------

  Future<void> readPhotos() => _read(pages.toList());

  Future<void> readPdf() async {
    final file = pdf.value;
    if (file != null) await _read([file]);
  }

  /// Leaving the processing screen abandons the result.
  void cancelReading() => _ocrCancelled = true;

  Future<void> _read(List<SourceDocument> documents) async {
    if (documents.isEmpty) return;
    _ocrCancelled = false;
    _startProgress();
    Get.toNamed(Routes.ocrProcessing);

    String nextRoute;
    Object? arguments;
    try {
      final extraction = await _documents.extract(documents);
      final draft = await _receipts.upsert(_draftFrom(extraction, documents));
      nextRoute = Routes.reviewSummary;
      arguments = draft.id;
    } on LockedDocumentException {
      nextRoute = Routes.pdfBlocked;
    } on UnreadableDocumentException {
      nextRoute = Routes.unreadable;
    } finally {
      _stopProgress();
    }
    if (_ocrCancelled || Get.currentRoute != Routes.ocrProcessing) return;
    Get.offNamed(nextRoute, arguments: arguments);
  }

  /// OCR output becomes a draft the user must review. A return deadline is
  /// never set here: it waits for the user's confirmation.
  Receipt _draftFrom(ReceiptExtraction e, List<SourceDocument> documents) {
    final now = _clock();
    final parsed = e.rawDate == null
        ? const ParsedReceiptDate()
        : ReceiptDateParser.parse(e.rawDate!);
    final itemsTotal = e.items.fold<int>(0, (s, i) => s + i.lineTotal);
    return Receipt(
      id: Ids.next('rcpt'),
      retailer: e.retailer ?? '',
      purchaseDate: parsed.date ?? Dates.dateOnly(now),
      total: Money.parse(e.rawTotal) ?? itemsTotal,
      items: e.items,
      reference: e.reference,
      source: _source,
      documents: [for (final d in documents) d.toReceiptDocument()],
      extraction: e,
      createdAt: now,
    );
  }

  // 21 · PDF blocked and 39 · Unreadable ------------------------------------

  void chooseAnotherFile() {
    pdf.value = null;
    Get.until((route) => route.settings.name == Routes.addSource);
  }

  void retakePhoto() {
    pages.clear();
    Get.until((route) => route.settings.name == Routes.addSource);
    chooseCamera();
  }

  void enterManually() {
    Get.until((route) => route.settings.name == Routes.addSource);
    Get.toNamed(Routes.manualReceipt);
  }

  // Helpers ----------------------------------------------------------------

  void _addPage(SourceDocument page) {
    if (!canAddPage) return;
    pages.add(page);
  }

  /// Returns to the page list, opening it if this is the first page.
  void _openPages() {
    Get.until(
      (route) =>
          route.settings.name == Routes.multiPhoto ||
          route.settings.name == Routes.addSource,
    );
    if (Get.currentRoute != Routes.multiPhoto) Get.toNamed(Routes.multiPhoto);
  }

  void _startProgress() {
    ocrProgress.value = 0.05;
    ocrStage.value = 0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      // Eases towards 90% and waits there for the real result.
      ocrProgress.value += (0.9 - ocrProgress.value) * 0.08;
      ocrStage.value = ocrProgress.value < 0.35
          ? 0
          : ocrProgress.value < 0.7
          ? 1
          : 2;
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    ocrProgress.value = 1;
    ocrStage.value = 2;
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    super.onClose();
  }
}
