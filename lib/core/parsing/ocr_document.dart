/// Text recognition output in a form the parser can use without depending
/// on ML Kit, so parsing is testable on any machine.
class OcrLine {
  const OcrLine(this.text, this.left, this.top, this.right, this.bottom);

  factory OcrLine.fromJson(Map<String, dynamic> j) => OcrLine(
    j['t'] as String,
    (j['l'] as num).toDouble(),
    (j['tp'] as num).toDouble(),
    (j['r'] as num).toDouble(),
    (j['b'] as num).toDouble(),
  );

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;

  Map<String, dynamic> toJson() => {
    't': text,
    'l': left,
    'tp': top,
    'r': right,
    'b': bottom,
  };
}

class OcrPage {
  const OcrPage({
    required this.width,
    required this.height,
    required this.lines,
  });

  factory OcrPage.fromJson(Map<String, dynamic> j) => OcrPage(
    width: (j['w'] as num).toDouble(),
    height: (j['h'] as num).toDouble(),
    lines: [
      for (final l in j['lines'] as List)
        OcrLine.fromJson(Map<String, dynamic>.from(l as Map)),
    ],
  );

  final double width;
  final double height;
  final List<OcrLine> lines;

  Map<String, dynamic> toJson() => {
    'w': width,
    'h': height,
    'lines': [for (final l in lines) l.toJson()],
  };
}

class OcrDocument {
  const OcrDocument(this.pages);

  /// Builds a document from plain text, one receipt line per text line.
  /// Used by tests and for digital PDFs.
  factory OcrDocument.fromPlainText(String text) {
    final rows = text.split('\n');
    return OcrDocument([
      OcrPage(
        width: 1000,
        height: rows.length * 40.0 + 40,
        lines: [
          for (var i = 0; i < rows.length; i++)
            if (rows[i].trim().isNotEmpty)
              OcrLine(rows[i], 20, i * 40.0 + 20, 980, i * 40.0 + 52),
        ],
      ),
    ]);
  }

  final List<OcrPage> pages;

  String get text => [
    for (final p in pages)
      for (final l in p.lines) l.text,
  ].join('\n');

  bool get isEmpty => pages.every((p) => p.lines.isEmpty);
}
