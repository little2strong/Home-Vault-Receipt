import 'enums.dart';
import 'firestore_values.dart';

/// Where an item's line sits on the original, as fractions of the page so
/// the highlight survives any zoom level.
class LineBox {
  const LineBox({
    required this.page,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });

  static LineBox? fromMap(Object? v) {
    if (v is! Map) return null;
    double d(Object? n) => n is num ? n.toDouble() : 0;
    return LineBox(
      page: v['page'] is num ? (v['page'] as num).toInt() : 0,
      x: d(v['x']),
      y: d(v['y']),
      w: d(v['w']),
      h: d(v['h']),
    );
  }

  final int page;
  final double x;
  final double y;
  final double w;
  final double h;

  Map<String, dynamic> toMap() => {
    'page': page,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
  };
}

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.purpose,
    required this.currency,
    this.receiptId,
    this.receiptNumber,
    this.purchaseDate,
    this.shop,
    this.carId,
    this.inHome = false,
    this.quantity = 1,
    this.unitPriceMinor,
    this.lineTotalMinor,
    this.status = ItemStatus.owned,
    this.highValue = false,
    this.serial,
    this.model,
    this.notes,
    this.lineBox,
    this.allocations = const {},
    this.estimated = false,
    this.yearBought,
    this.photoCount = 0,
    this.coverThumbPath,
    this.warrantyEnd,
    this.extracted = const {},
    this.createdAt,
  });

  factory Item.fromMap(String id, Map<String, dynamic> m) => Item(
    id: id,
    name: Fs.str(m['name']) ?? 'Unnamed item',
    category: Category.fromName(Fs.str(m['category'])),
    type: ItemType.fromName(Fs.str(m['type'])),
    purpose: Purpose.fromName(Fs.str(m['purpose'])),
    currency: Fs.str(m['currency']) ?? 'GBP',
    receiptId: Fs.str(m['receiptId']),
    receiptNumber: Fs.str(m['receiptNumber']),
    purchaseDate: Fs.date(m['purchaseDate']),
    shop: Fs.str(m['shop']),
    carId: Fs.str(m['carId']),
    inHome: Fs.boolOr(m['inHome']),
    quantity: Fs.intOr(m['quantity'], 1),
    unitPriceMinor: Fs.intOrNull(m['unitPriceMinor']),
    lineTotalMinor: Fs.intOrNull(m['lineTotalMinor']),
    status: ItemStatus.fromName(Fs.str(m['status'])),
    highValue: Fs.boolOr(m['highValue']),
    serial: Fs.str(m['serial']),
    model: Fs.str(m['model']),
    notes: Fs.str(m['notes']),
    lineBox: LineBox.fromMap(m['lineBox']),
    allocations: Fs.intMap(m['allocations']),
    estimated: Fs.boolOr(m['estimated']),
    yearBought: Fs.intOrNull(m['yearBought']),
    photoCount: Fs.intOr(m['photoCount']),
    coverThumbPath: Fs.str(m['coverThumbPath']),
    warrantyEnd: Fs.date(m['warrantyEnd']),
    extracted: Fs.map(m['extracted']),
    createdAt: Fs.time(m['createdAt']),
  );

  final String id;
  final String name;
  final Category category;
  final ItemType type;
  final Purpose purpose;
  final String currency;

  /// Null for older belongings added without a receipt.
  final String? receiptId;
  final String? receiptNumber;
  final DateTime? purchaseDate;
  final String? shop;
  final String? carId;
  final bool inHome;
  final int quantity;
  final int? unitPriceMinor;
  final int? lineTotalMinor;
  final ItemStatus status;
  final bool highValue;
  final String? serial;
  final String? model;
  final String? notes;
  final LineBox? lineBox;

  /// Room id → quantity in that room. One entry unless the quantity is
  /// split (2 × lamp → bedroom 1, sitting room 1).
  final Map<String, int> allocations;

  /// True when the price is the user's estimate (no receipt).
  final bool estimated;
  final int? yearBought;
  final int photoCount;
  final String? coverThumbPath;
  final DateTime? warrantyEnd;

  /// What text recognition read, kept apart from the confirmed values above
  /// so a re-scan never overwrites what the user confirmed.
  final Map<String, dynamic> extracted;
  final DateTime? createdAt;

  bool get hasReceipt => receiptId != null;
  bool get isPhysical => type == ItemType.physical;
  bool get isSplit => allocations.length > 1;
  List<String> get roomIds => allocations.keys.toList();

  /// Inventory = Physical items, In my home on, status Owned.
  bool get inInventory => isPhysical && inHome && status == ItemStatus.owned;

  int get value => lineTotalMinor ?? ((unitPriceMinor ?? 0) * quantity);

  int get unitValue =>
      unitPriceMinor ?? (quantity > 0 ? (lineTotalMinor ?? 0) ~/ quantity : 0);

  /// What this item contributes to one room's total.
  int valueInRoom(String roomId) =>
      isSplit ? unitValue * (allocations[roomId] ?? 0) : value;

  /// `IKEA table lamp × 2`
  String get displayName => quantity > 1 ? '$name × $quantity' : name;
}
