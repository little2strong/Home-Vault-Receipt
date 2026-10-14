import 'enums.dart';
import 'firestore_values.dart';

/// One receipt document per receipt, however many items. [number] is the
/// readable HV-000123 assigned by the `saveReceipt` Function.
class Receipt {
  const Receipt({
    required this.id,
    required this.number,
    required this.currency,
    required this.source,
    this.shop,
    this.purchaseDate,
    this.totalMinor,
    this.taxMinor,
    this.orderNumber,
    this.originalPaths = const [],
    this.originalTypes = const [],
    this.checksum,
    this.itemCount = 0,
    this.itemPreview,
    this.returnWording,
    this.confirmedAt,
    this.revision = 1,
  });

  factory Receipt.fromMap(String id, Map<String, dynamic> m) => Receipt(
    id: id,
    number: Fs.str(m['number']) ?? '',
    currency: Fs.str(m['currency']) ?? 'GBP',
    source: ReceiptSource.fromName(Fs.str(m['source'])),
    shop: Fs.str(m['shop']),
    purchaseDate: Fs.date(m['purchaseDate']),
    totalMinor: Fs.intOrNull(m['totalMinor']),
    taxMinor: Fs.intOrNull(m['taxMinor']),
    orderNumber: Fs.str(m['orderNumber']),
    originalPaths: Fs.strings(m['originalPaths']),
    originalTypes: Fs.strings(m['originalTypes']),
    checksum: Fs.str(m['checksum']),
    itemCount: Fs.intOr(m['itemCount']),
    itemPreview: Fs.str(m['itemPreview']),
    returnWording: Fs.str(m['returnWording']),
    confirmedAt: Fs.time(m['confirmedAt']),
    revision: Fs.intOr(m['revision'], 1),
  );

  final String id;
  final String number;

  /// Unknown values stay null and show as "Not stated".
  final String? shop;
  final DateTime? purchaseDate;
  final String currency;
  final int? totalMinor;
  final int? taxMinor;
  final String? orderNumber;
  final ReceiptSource source;

  /// Storage paths only, never URLs, so the file store can be swapped.
  final List<String> originalPaths;

  /// `image/jpeg` or `application/pdf`, parallel to [originalPaths].
  final List<String> originalTypes;
  final String? checksum;
  final int itemCount;

  /// e.g. `Samsung 55" QLED TV` — the first item, for list rows.
  final String? itemPreview;

  /// Returns sentence as printed; a deadline is only set once confirmed.
  final String? returnWording;
  final DateTime? confirmedAt;
  final int revision;

  bool get hasOriginal => originalPaths.isNotEmpty;
  bool get isPdf => originalTypes.contains('application/pdf');

  String get displayShop => shop ?? 'Shop not stated';

  /// `Camera scan · 2 pages`
  String get sourceLine {
    final pages = originalPaths.length;
    if (source == ReceiptSource.manual) return source.label;
    if (isPdf || pages <= 1) return source.label;
    return '${source.label} · $pages pages';
  }

  Map<String, dynamic> toEditableMap() => {
    'shop': shop,
    'purchaseDate': Fs.iso(purchaseDate),
    'currency': currency,
    'totalMinor': totalMinor,
    'taxMinor': taxMinor,
    'orderNumber': orderNumber,
  };
}
