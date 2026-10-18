import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../models/receipt_draft.dart';
import '../parsing/ocr_document.dart';

class UnreadableDocument implements Exception {
  const UnreadableDocument(this.message);

  final String message;

  @override
  String toString() => message;
}

/// On-device text recognition (ML Kit), so receipt images are never sent to
/// a scanning service. Keeps every line with its bounding box.
class TextRecognitionService {
  static const _maxRenderEdge = 4096.0;

  TextRecognizer? _recognizer;

  TextRecognizer get _ml =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrDocument> recognise(List<DraftPage> pages) async {
    final out = <OcrPage>[];
    for (final page in pages) {
      if (page.isPdf) {
        out.addAll(await _pdf(page.localPath));
      } else {
        out.add(await _image(page.localPath));
      }
    }
    return OcrDocument(out);
  }

  Future<OcrPage> _image(String path) async {
    final size = await imageSize(File(path).readAsBytesSync());
    final result = await _ml.processImage(InputImage.fromFilePath(path));
    return OcrPage(
      width: size.width,
      height: size.height,
      lines: [
        for (final block in result.blocks)
          for (final line in block.lines)
            OcrLine(
              line.text,
              line.boundingBox.left,
              line.boundingBox.top,
              line.boundingBox.right,
              line.boundingBox.bottom,
            ),
      ],
    );
  }

  /// Digital and scanned PDFs: each page is rendered, then read.
  Future<List<OcrPage>> _pdf(String path) async {
    final doc = await PdfDocument.openFile(path);
    final dir = await getTemporaryDirectory();
    final pages = <OcrPage>[];
    try {
      for (var n = 1; n <= doc.pagesCount; n++) {
        final page = await doc.getPage(n);
        File? file;
        try {
          // Twice the page size reads small print well; a long till roll
          // is capped so it can't run the phone out of memory.
          final longest = math.max(page.width, page.height);
          final scale = math.min(2.0, _maxRenderEdge / longest);
          final w = page.width * scale, h = page.height * scale;
          final render = await page.render(
            width: w,
            height: h,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 90,
          );
          if (render == null) continue;
          file = File(
            '${dir.path}/ocr-${DateTime.now().microsecondsSinceEpoch}.jpg',
          )..writeAsBytesSync(render.bytes);
          final result = await _ml.processImage(
            InputImage.fromFilePath(file.path),
          );
          pages.add(
            OcrPage(
              width: w,
              height: h,
              lines: [
                for (final block in result.blocks)
                  for (final line in block.lines)
                    OcrLine(
                      line.text,
                      line.boundingBox.left,
                      line.boundingBox.top,
                      line.boundingBox.right,
                      line.boundingBox.bottom,
                    ),
              ],
            ),
          );
        } finally {
          if (file != null && file.existsSync()) file.deleteSync();
          await page.close();
        }
      }
    } finally {
      await doc.close();
    }
    return pages;
  }

  /// Upright size, allowing for EXIF rotation, so boxes line up with what
  /// the viewer shows.
  static Future<ui.Size> imageSize(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    var w = descriptor.width.toDouble(), h = descriptor.height.toDouble();
    descriptor.dispose();
    buffer.dispose();
    try {
      final exif = img.decodeJpgExif(bytes);
      final orientation = exif?.imageIfd.orientation ?? 1;
      if (orientation >= 5 && orientation <= 8) (w, h) = (h, w);
    } catch (_) {}
    return ui.Size(w, h);
  }

  void dispose() => _recognizer?.close();
}
