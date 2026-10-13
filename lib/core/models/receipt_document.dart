enum DocumentKind { image, pdf }

/// The original evidence attached to a receipt (photos or a PDF invoice).
class ReceiptDocument {
  const ReceiptDocument({
    required this.id,
    required this.kind,
    required this.fileName,
    this.pageCount = 1,
    this.sizeBytes = 0,
    this.uploaded = false,
  });

  factory ReceiptDocument.fromJson(Map<String, dynamic> json) =>
      ReceiptDocument(
        id: json['id'] as String,
        kind: DocumentKind.values.byName(json['kind'] as String),
        fileName: json['file_name'] as String,
        pageCount: json['page_count'] as int? ?? 1,
        sizeBytes: json['size_bytes'] as int? ?? 0,
        uploaded: json['uploaded'] as bool? ?? false,
      );

  final String id;
  final DocumentKind kind;
  final String fileName;
  final int pageCount;
  final int sizeBytes;

  /// True once the cloud copy is verified. Until then the record is not
  /// reported as saved.
  final bool uploaded;

  ReceiptDocument copyWith({bool? uploaded}) => ReceiptDocument(
    id: id,
    kind: kind,
    fileName: fileName,
    pageCount: pageCount,
    sizeBytes: sizeBytes,
    uploaded: uploaded ?? this.uploaded,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'file_name': fileName,
    'page_count': pageCount,
    'size_bytes': sizeBytes,
    'uploaded': uploaded,
  };
}
