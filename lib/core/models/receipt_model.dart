import '../utils/dates.dart';
import 'product_category.dart';
import 'receipt_document.dart';
import 'receipt_extraction.dart';
import 'receipt_item.dart';

enum ReceiptSource {
  camera('Camera'),
  photos('Photos'),
  pdf('PDF invoice'),
  manual('Manual entry');

  const ReceiptSource(this.label);

  final String label;
}

/// Save states are kept distinct so the UI never claims more than is true.
enum ReceiptStatus {
  /// Extracted or typed in, waiting for the user's review.
  draft('Draft · needs review'),

  /// Confirmed and stored on this device, waiting for a connection.
  queued('Waiting for connection'),

  /// Confirmed, but the upload was interrupted. The draft is preserved.
  failed('Upload interrupted · draft preserved'),

  /// Confirmed and stored in the vault with verified originals.
  saved('Saved');

  const ReceiptStatus(this.label);

  final String label;
}

enum DeadlineSource {
  statedOnReceipt('Date stated on receipt'),
  addedByUser('Date added by you');

  const DeadlineSource(this.label);

  final String label;
}

class Receipt {
  const Receipt({
    required this.id,
    required this.retailer,
    required this.purchaseDate,
    required this.total,
    required this.createdAt,
    this.currency = 'GBP',
    this.items = const [],
    this.reference,
    this.returnDeadline,
    this.deadlineSource,
    this.reminderDaysBefore = defaultReminderDays,
    this.reminderMinutes = defaultReminderMinutes,
    this.notes,
    this.source = ReceiptSource.manual,
    this.documents = const [],
    this.extraction,
    this.status = ReceiptStatus.draft,
    this.updatedAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    id: json['id'] as String,
    retailer: json['retailer'] as String,
    purchaseDate: DateTime.parse(json['purchase_date'] as String),
    total: json['total'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    currency: json['currency'] as String? ?? 'GBP',
    items: [
      for (final item in json['items'] as List? ?? const [])
        ReceiptItem.fromJson(item as Map<String, dynamic>),
    ],
    reference: json['reference'] as String?,
    returnDeadline: json['return_deadline'] == null
        ? null
        : DateTime.parse(json['return_deadline'] as String),
    deadlineSource: json['deadline_source'] == null
        ? null
        : DeadlineSource.values.byName(json['deadline_source'] as String),
    reminderDaysBefore: [
      for (final d
          in json['reminder_days_before'] as List? ?? defaultReminderDays)
        d as int,
    ],
    reminderMinutes: json['reminder_minutes'] as int? ?? defaultReminderMinutes,
    notes: json['notes'] as String?,
    source: ReceiptSource.values.byName(json['source'] as String? ?? 'manual'),
    documents: [
      for (final doc in json['documents'] as List? ?? const [])
        ReceiptDocument.fromJson(doc as Map<String, dynamic>),
    ],
    extraction: json['extraction'] == null
        ? null
        : ReceiptExtraction.fromJson(
            json['extraction'] as Map<String, dynamic>,
          ),
    status: ReceiptStatus.values.byName(json['status'] as String? ?? 'saved'),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
  );

  static const defaultReminderDays = [7, 1];

  /// 09:00 local time.
  static const defaultReminderMinutes = 9 * 60;

  final String id;
  final String retailer;

  /// Calendar date only; time of day is never meaningful on a receipt.
  final DateTime purchaseDate;

  /// Grand total in minor units, as printed on the receipt.
  final int total;
  final String currency;
  final List<ReceiptItem> items;
  final String? reference;

  /// Only ever set from a date the user confirmed. Missing return dates stay
  /// blank rather than being guessed.
  final DateTime? returnDeadline;
  final DeadlineSource? deadlineSource;
  final List<int> reminderDaysBefore;
  final int reminderMinutes;
  final String? notes;
  final ReceiptSource source;
  final List<ReceiptDocument> documents;
  final ReceiptExtraction? extraction;
  final ReceiptStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isSaved => status == ReceiptStatus.saved;
  bool get hasOriginal => documents.isNotEmpty;
  bool get hasReturnDeadline => returnDeadline != null;
  bool get originalsUploaded => documents.every((d) => d.uploaded);

  int get itemsTotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  /// Product lines can legitimately be incomplete (discounts, delivery), so
  /// a mismatch is surfaced for review, never blocked.
  bool get itemsMatchTotal => items.isEmpty || itemsTotal == total;

  Set<ProductCategory> get categories => {for (final i in items) i.category};

  /// `Sony wireless headphones` or `3 products`.
  String get headline => switch (items.length) {
    0 => 'No products listed',
    1 => items.first.name,
    final n => '$n products',
  };

  int? daysUntilReturn(DateTime today) =>
      returnDeadline == null ? null : Dates.daysBetween(today, returnDeadline!);

  bool isReturnOpen(DateTime today) => (daysUntilReturn(today) ?? -1) >= 0;

  Receipt copyWith({
    String? retailer,
    DateTime? purchaseDate,
    int? total,
    String? currency,
    List<ReceiptItem>? items,
    String? reference,
    DateTime? returnDeadline,
    DeadlineSource? deadlineSource,
    List<int>? reminderDaysBefore,
    int? reminderMinutes,
    String? notes,
    ReceiptSource? source,
    List<ReceiptDocument>? documents,
    ReceiptExtraction? extraction,
    ReceiptStatus? status,
    DateTime? updatedAt,
    bool clearReference = false,
    bool clearReturnDeadline = false,
    bool clearNotes = false,
  }) => Receipt(
    id: id,
    retailer: retailer ?? this.retailer,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    total: total ?? this.total,
    createdAt: createdAt,
    currency: currency ?? this.currency,
    items: items ?? this.items,
    reference: clearReference ? null : (reference ?? this.reference),
    returnDeadline: clearReturnDeadline
        ? null
        : (returnDeadline ?? this.returnDeadline),
    deadlineSource: clearReturnDeadline
        ? null
        : (deadlineSource ?? this.deadlineSource),
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    notes: clearNotes ? null : (notes ?? this.notes),
    source: source ?? this.source,
    documents: documents ?? this.documents,
    extraction: extraction ?? this.extraction,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'retailer': retailer,
    'purchase_date': purchaseDate.toIso8601String(),
    'total': total,
    'created_at': createdAt.toIso8601String(),
    'currency': currency,
    'items': [for (final item in items) item.toJson()],
    'reference': reference,
    'return_deadline': returnDeadline?.toIso8601String(),
    'deadline_source': deadlineSource?.name,
    'reminder_days_before': reminderDaysBefore,
    'reminder_minutes': reminderMinutes,
    'notes': notes,
    'source': source.name,
    'documents': [for (final doc in documents) doc.toJson()],
    'extraction': extraction?.toJson(),
    'status': status.name,
    'updated_at': updatedAt?.toIso8601String(),
  };
}
