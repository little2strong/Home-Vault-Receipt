import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../models/receipt_draft.dart';
import 'app_config.dart';
import 'firebase_bootstrap.dart';
import 'text_recognition_service.dart';

class CaptureProblem implements Exception {
  const CaptureProblem(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gets receipt pages onto the device: the document scanner, the photo
/// library or a PDF. Files are copied into the app's own folder so a draft
/// survives the app closing.
class CaptureService {
  final _picker = ImagePicker();

  /// Android's ML Kit scanner: automatic edge detection, auto-capture,
  /// multi-page and crop. iOS uses the in-app camera instead.
  bool get hasDocumentScanner => AppConfig.isAndroid;

  Future<Directory> draftDir(String draftId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/drafts/$draftId');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<List<DraftPage>> scanDocument(String draftId) async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        pageLimit: Limits.receiptPages,
        documentFormats: const {DocumentFormat.jpeg},
        mode: ScannerMode.full,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final paths = result.images ?? const [];
      return [for (final p in paths) await keepImage(draftId, File(p))];
    } finally {
      await scanner.close();
    }
  }

  Future<List<DraftPage>> pickPhotos(String draftId) async {
    final picked = await _picker.pickMultiImage(limit: Limits.receiptPages);
    return [
      for (final x in picked.take(Limits.receiptPages))
        await keepImage(draftId, File(x.path)),
    ];
  }

  /// Online orders and emailed invoices.
  Future<DraftPage?> pickPdf(String draftId) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (files.isEmpty) return null;
    final source = files.first.path;
    if (source == null) return null;

    PdfDocument doc;
    try {
      doc = await PdfDocument.openFile(source);
    } catch (_) {
      throw const CaptureProblem(
        "This PDF is locked or damaged, so we can't read it. Save an unlocked "
        'copy, or type the receipt in.',
      );
    }
    final pageCount = doc.pagesCount;
    await doc.close();
    if (pageCount > Limits.pdfMaxPages) {
      throw CaptureProblem(
        'This PDF has $pageCount pages. Import one with up to '
        '${Limits.pdfMaxPages} pages.',
      );
    }
    final dir = await draftDir(draftId);
    final target = File('${dir.path}/original-1.pdf');
    await File(source).copy(target.path);
    return DraftPage(localPath: target.path, contentType: 'application/pdf');
  }

  Future<DraftPage> keepImage(String draftId, File file) async {
    final dir = await draftDir(draftId);
    final name = 'page-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final target = await file.copy('${dir.path}/$name');
    final size = await TextRecognitionService.imageSize(
      target.readAsBytesSync(),
    );
    return DraftPage(
      localPath: target.path,
      contentType: 'image/jpeg',
      width: size.width,
      height: size.height,
    );
  }

  Future<DraftPage> keepBytes(String draftId, Uint8List jpeg) async {
    final dir = await draftDir(draftId);
    final target = File(
      '${dir.path}/page-${DateTime.now().microsecondsSinceEpoch}.jpg',
    )..writeAsBytesSync(jpeg);
    final size = await TextRecognitionService.imageSize(jpeg);
    return DraftPage(
      localPath: target.path,
      contentType: 'image/jpeg',
      width: size.width,
      height: size.height,
    );
  }

  /// SHA-256 over all pages in order, for the duplicate check.
  Future<String?> checksum(List<DraftPage> pages) async {
    if (pages.isEmpty) return null;
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    for (final p in pages) {
      final file = File(p.localPath);
      if (!file.existsSync()) return null;
      input.add(await file.readAsBytes());
    }
    input.close();
    return output.events.single.toString();
  }

  /// One item photo from the camera or gallery.
  Future<XFile?> pickItemPhoto({required bool camera}) => _picker.pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    requestFullMetadata: true,
  );

  Future<void> deleteDraftFiles(String draftId) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/drafts/$draftId');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// Collects the single digest from a chunked hash.
class AccumulatorSink<T> implements Sink<T> {
  final events = <T>[];

  @override
  void add(T event) => events.add(event);

  @override
  void close() {}
}
