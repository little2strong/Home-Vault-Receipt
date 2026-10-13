import '../error/app_exception.dart';
import '../models/product_category.dart';
import '../models/receipt_document.dart';
import '../models/receipt_extraction.dart';
import '../models/receipt_item.dart';
import '../utils/dates.dart';
import '../utils/formatters.dart';
import '../utils/ids.dart';

/// Which sample receipt a source document shows. This build has no camera
/// plugin or OCR engine, so capture and recognition use sample documents.
enum SampleReceipt { currys, ikea, johnLewis, blurry }

/// A photo or PDF chosen by the user, before it becomes a receipt record.
class SourceDocument {
  const SourceDocument({
    required this.id,
    required this.kind,
    required this.fileName,
    required this.sample,
    this.pageCount = 1,
    this.sizeBytes = 0,
    this.passwordProtected = false,
    this.note,
  });

  final String id;
  final DocumentKind kind;
  final String fileName;
  final SampleReceipt sample;
  final int pageCount;
  final int sizeBytes;
  final bool passwordProtected;

  /// User-facing hint such as `Top of receipt`.
  final String? note;

  SourceDocument withNote(String? note) => SourceDocument(
    id: id,
    kind: kind,
    fileName: fileName,
    sample: sample,
    pageCount: pageCount,
    sizeBytes: sizeBytes,
    passwordProtected: passwordProtected,
    note: note,
  );

  ReceiptDocument toReceiptDocument() => ReceiptDocument(
    id: id,
    kind: kind,
    fileName: fileName,
    pageCount: pageCount,
    sizeBytes: sizeBytes,
  );
}

/// Capture and text recognition. Every method is the seam where a real
/// camera, file picker and OCR engine plug in.
class DocumentService {
  DocumentService({
    this._clock = DateTime.now,
    this.processingTime = const Duration(milliseconds: 1600),
  });

  static const maxPhotos = 10;
  static const maxPdfPages = 20;

  final Clock _clock;
  final Duration processingTime;

  DateTime get _today => Dates.dateOnly(_clock());

  SourceDocument cameraCapture() => SourceDocument(
    id: Ids.next('doc'),
    kind: DocumentKind.image,
    fileName: 'camera-${_clock().millisecondsSinceEpoch}.jpg',
    sample: SampleReceipt.currys,
    sizeBytes: 1450000,
  );

  List<SourceDocument> samplePhotos() => [
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.image,
      fileName: 'ikea-receipt.jpg',
      sample: SampleReceipt.ikea,
      sizeBytes: 2100000,
    ),
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.image,
      fileName: 'currys-screenshot.png',
      sample: SampleReceipt.currys,
      sizeBytes: 640000,
    ),
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.image,
      fileName: 'faded-receipt.jpg',
      sample: SampleReceipt.blurry,
      sizeBytes: 1200000,
    ),
  ];

  List<SourceDocument> samplePdfs() => [
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.pdf,
      fileName: 'invoice-john-lewis.pdf',
      sample: SampleReceipt.johnLewis,
      pageCount: 2,
      sizeBytes: 820 * 1024,
    ),
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.pdf,
      fileName: 'order-statement-protected.pdf',
      sample: SampleReceipt.johnLewis,
      pageCount: 3,
      sizeBytes: 410 * 1024,
      passwordProtected: true,
    ),
    SourceDocument(
      id: Ids.next('doc'),
      kind: DocumentKind.pdf,
      fileName: 'appliance-manual.pdf',
      sample: SampleReceipt.johnLewis,
      pageCount: 64,
      sizeBytes: 9 * 1024 * 1024,
    ),
  ];

  /// Throws before any processing when a PDF cannot be read at all.
  void checkPdf(SourceDocument pdf) {
    if (pdf.passwordProtected) throw const LockedDocumentException();
    if (pdf.pageCount > maxPdfPages) {
      throw AppException(
        'This PDF has ${pdf.pageCount} pages. Import up to $maxPdfPages pages.',
      );
    }
  }

  Future<ReceiptExtraction> extract(List<SourceDocument> pages) async {
    if (pages.isEmpty) throw const UnreadableDocumentException();
    for (final page in pages) {
      if (page.kind == DocumentKind.pdf) checkPdf(page);
    }
    await Future<void>.delayed(processingTime);
    return switch (pages.first.sample) {
      SampleReceipt.currys => _currys(),
      SampleReceipt.ikea => _ikea(),
      SampleReceipt.johnLewis => _johnLewis(),
      SampleReceipt.blurry => throw const UnreadableDocumentException(),
    };
  }

  String _numeric(DateTime d, {bool shortYear = true}) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = shortYear
        ? (d.year % 100).toString().padLeft(2, '0')
        : '${d.year}';
    return '$dd/$mm/$yy';
  }

  ReceiptExtraction _currys() {
    final bought = _today;
    final deadline = Dates.addDays(bought, 13);
    return ReceiptExtraction(
      retailer: 'Currys',
      rawDate: _numeric(bought),
      rawTotal: '179.00',
      reference: 'CR-${bought.year}-10482',
      returnWording: 'Returns accepted until ${Formatters.date(deadline)}.',
      suggestedReturnDeadline: deadline,
      items: [
        ReceiptItem(
          id: Ids.next('item'),
          name: 'Sony wireless headphones',
          sourceDescription: 'SONY WH-1000XM5',
          lineTotal: 17900,
          category: ProductCategory.electronics,
        ),
      ],
      uncertainFields: {ReviewField.purchaseDate, ReviewField.returnDate},
    );
  }

  ReceiptExtraction _ikea() {
    final bought = Dates.addDays(_today, -1);
    return ReceiptExtraction(
      retailer: 'IKEA',
      rawDate: _numeric(bought, shortYear: false),
      rawTotal: '428.00',
      reference: 'IK-${bought.year}-55120',
      items: [
        ReceiptItem(
          id: Ids.next('item'),
          name: 'LANDSKRONA sofa',
          sourceDescription: 'LANDSKRONA 3-SEAT SOFA',
          lineTotal: 34900,
          category: ProductCategory.home,
        ),
        ReceiptItem(
          id: Ids.next('item'),
          name: 'LACK side table',
          sourceDescription: 'LACK SIDE TBL 55X55',
          lineTotal: 2900,
          category: ProductCategory.home,
        ),
        ReceiptItem(
          id: Ids.next('item'),
          name: 'Floor lamp',
          sourceDescription: 'HEKTAR FLOOR LAMP',
          lineTotal: 5000,
          category: ProductCategory.home,
        ),
      ],
      uncertainFields: {ReviewField.returnDate},
    );
  }

  ReceiptExtraction _johnLewis() {
    final bought = Dates.addDays(_today, -2);
    return ReceiptExtraction(
      retailer: 'John Lewis',
      rawDate:
          '${bought.day.toString().padLeft(2, '0')} '
          '${Formatters.months[bought.month - 1].toUpperCase()} ${bought.year}',
      rawTotal: '249.00',
      reference: 'JL-${bought.year}-88317',
      returnWording: 'Return within 35 days of delivery.',
      suggestedReturnDeadline: Dates.addDays(bought, 35),
      items: [
        ReceiptItem(
          id: Ids.next('item'),
          name: 'Coffee machine',
          sourceDescription: 'BARISTA ESPRESSO BES870',
          lineTotal: 24900,
          category: ProductCategory.appliances,
        ),
      ],
      uncertainFields: {ReviewField.returnDate},
    );
  }
}
