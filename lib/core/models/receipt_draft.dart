import '../utils/dates.dart';
import 'enums.dart';
import 'item.dart';

/// A captured page held on this device until the receipt is saved.
class DraftPage {
  const DraftPage({
    required this.localPath,
    required this.contentType,
    this.width = 0,
    this.height = 0,
  });

  factory DraftPage.fromJson(Map<String, dynamic> j) => DraftPage(
    localPath: j['localPath'] as String,
    contentType: j['contentType'] as String? ?? 'image/jpeg',
    width: (j['width'] as num?)?.toDouble() ?? 0,
    height: (j['height'] as num?)?.toDouble() ?? 0,
  );

  final String localPath;
  final String contentType;
  final double width;
  final double height;

  bool get isPdf => contentType == 'application/pdf';

  String get extension => isPdf ? 'pdf' : 'jpg';

  Map<String, dynamic> toJson() => {
    'localPath': localPath,
    'contentType': contentType,
    'width': width,
    'height': height,
  };
}

/// One line on the receipt being reviewed. Extracted and confirmed values
/// are kept separately: [extracted] is never edited after recognition.
class DraftItem {
  DraftItem({
    required this.id,
    required this.name,
    this.category = Category.other,
    ItemType? type,
    this.purpose = Purpose.home,
    this.carId,
    this.inHome = true,
    Map<String, int>? allocations,
    this.quantity = 1,
    this.unitPriceMinor,
    this.lineTotalMinor,
    this.lineBox,
    this.serial,
    this.model,
    this.notes,
    this.highValue = false,
    this.warrantyEnd,
    this.warrantyMonths,
    Map<String, dynamic>? extracted,
    this.typeTouched = false,
  }) : type = type ?? category.defaultType,
       allocations = allocations ?? {},
       extracted = extracted ?? {};

  factory DraftItem.fromJson(Map<String, dynamic> j) => DraftItem(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    category: Category.fromName(j['category'] as String?),
    type: ItemType.fromName(j['type'] as String?),
    purpose: Purpose.fromName(j['purpose'] as String?),
    carId: j['carId'] as String?,
    inHome: j['inHome'] as bool? ?? true,
    allocations: {
      for (final e in (j['allocations'] as Map? ?? const {}).entries)
        '${e.key}': (e.value as num).toInt(),
    },
    quantity: (j['quantity'] as num?)?.toInt() ?? 1,
    unitPriceMinor: (j['unitPriceMinor'] as num?)?.toInt(),
    lineTotalMinor: (j['lineTotalMinor'] as num?)?.toInt(),
    lineBox: LineBox.fromMap(j['lineBox']),
    serial: j['serial'] as String?,
    model: j['model'] as String?,
    notes: j['notes'] as String?,
    highValue: j['highValue'] as bool? ?? false,
    warrantyEnd: Dates.parseIso(j['warrantyEnd'] as String?),
    warrantyMonths: (j['warrantyMonths'] as num?)?.toInt(),
    extracted: Map<String, dynamic>.from(j['extracted'] as Map? ?? const {}),
    typeTouched: j['typeTouched'] as bool? ?? false,
  );

  final String id;
  String name;
  Category category;
  ItemType type;
  Purpose purpose;
  String? carId;
  bool inHome;
  Map<String, int> allocations;
  int quantity;
  int? unitPriceMinor;
  int? lineTotalMinor;
  LineBox? lineBox;
  String? serial;
  String? model;
  String? notes;
  bool highValue;
  DateTime? warrantyEnd;
  int? warrantyMonths;
  final Map<String, dynamic> extracted;

  /// Once the user picks a Type, a category change no longer resets it.
  bool typeTouched;

  bool get isPhysical => type == ItemType.physical;
  String? get roomId => allocations.isEmpty ? null : allocations.keys.first;
  bool get isSplit => allocations.length > 1;
  int get value => lineTotalMinor ?? (unitPriceMinor ?? 0) * quantity;

  void setCategory(Category c) {
    category = c;
    if (!typeTouched) type = c.defaultType;
  }

  /// Puts the whole quantity in one room.
  void setRoom(String? roomId) {
    allocations = roomId == null ? {} : {roomId: quantity};
  }

  DraftItem copy() => DraftItem.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'type': type.name,
    'purpose': purpose.name,
    'carId': carId,
    'inHome': inHome,
    'allocations': allocations,
    'quantity': quantity,
    'unitPriceMinor': unitPriceMinor,
    'lineTotalMinor': lineTotalMinor,
    'lineBox': lineBox?.toMap(),
    'serial': serial,
    'model': model,
    'notes': notes,
    'highValue': highValue,
    'warrantyEnd': warrantyEnd == null ? null : Dates.toIso(warrantyEnd!),
    'warrantyMonths': warrantyMonths,
    'extracted': extracted,
    'typeTouched': typeTouched,
  };

  /// The payload `saveReceipt` writes as the item's confirmed values.
  Map<String, dynamic> toSavePayload() {
    final physical = isPhysical;
    return {
      'name': name.trim().isEmpty ? 'Unnamed item' : name.trim(),
      'category': category.name,
      'type': type.name,
      'purpose': purpose.name,
      'carId': purpose == Purpose.car ? carId : null,
      'inHome': physical && inHome,
      'allocations': physical && inHome ? allocations : <String, int>{},
      'quantity': quantity,
      'unitPriceMinor': unitPriceMinor,
      'lineTotalMinor': lineTotalMinor,
      'lineBox': lineBox?.toMap(),
      'serial': serial,
      'model': model,
      'notes': notes,
      'highValue': highValue,
      'extracted': extracted,
    };
  }
}

enum DraftState {
  /// Being captured or reviewed.
  editing,

  /// Confirmed by the user; waiting for a connection to save.
  waiting,

  /// The last save attempt failed; the draft is kept for retry.
  failed,
}

/// Everything about a receipt before the server confirms it. Persisted on
/// the device so nothing is lost if the app closes mid-capture.
class ReceiptDraft {
  ReceiptDraft({
    required this.id,
    required this.saveKey,
    required this.source,
    required this.createdAt,
    List<DraftPage>? pages,
    List<DraftItem>? items,
    this.shop,
    this.purchaseDate,
    this.currency = 'GBP',
    this.totalMinor,
    this.taxMinor,
    this.orderNumber,
    this.returnWording,
    this.returnDeadline,
    this.returnFromWording = false,
    this.checksum,
    this.ocrText,
    Map<String, dynamic>? extracted,
    this.sameForAll = true,
    this.sharedPurpose = Purpose.home,
    this.sharedRoomId,
    this.sharedCarId,
    this.state = DraftState.editing,
    List<String>? uploadedPaths,
    this.duplicateAcknowledged = false,
    this.lastError,
  }) : pages = pages ?? [],
       items = items ?? [],
       extracted = extracted ?? {},
       uploadedPaths = uploadedPaths ?? [];

  factory ReceiptDraft.fromJson(Map<String, dynamic> j) => ReceiptDraft(
    id: j['id'] as String,
    saveKey: j['saveKey'] as String,
    source: ReceiptSource.fromName(j['source'] as String?),
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
    pages: [
      for (final p in j['pages'] as List? ?? const [])
        DraftPage.fromJson(Map<String, dynamic>.from(p as Map)),
    ],
    items: [
      for (final i in j['items'] as List? ?? const [])
        DraftItem.fromJson(Map<String, dynamic>.from(i as Map)),
    ],
    shop: j['shop'] as String?,
    purchaseDate: Dates.parseIso(j['purchaseDate'] as String?),
    currency: j['currency'] as String? ?? 'GBP',
    totalMinor: (j['totalMinor'] as num?)?.toInt(),
    taxMinor: (j['taxMinor'] as num?)?.toInt(),
    orderNumber: j['orderNumber'] as String?,
    returnWording: j['returnWording'] as String?,
    returnDeadline: Dates.parseIso(j['returnDeadline'] as String?),
    returnFromWording: j['returnFromWording'] as bool? ?? false,
    checksum: j['checksum'] as String?,
    ocrText: j['ocrText'] as String?,
    extracted: Map<String, dynamic>.from(j['extracted'] as Map? ?? const {}),
    sameForAll: j['sameForAll'] as bool? ?? true,
    sharedPurpose: Purpose.fromName(j['sharedPurpose'] as String?),
    sharedRoomId: j['sharedRoomId'] as String?,
    sharedCarId: j['sharedCarId'] as String?,
    state: DraftState.values.asNameMap()[j['state']] ?? DraftState.editing,
    uploadedPaths: [
      for (final p in j['uploadedPaths'] as List? ?? const []) p as String,
    ],
    duplicateAcknowledged: j['duplicateAcknowledged'] as bool? ?? false,
    lastError: j['lastError'] as String?,
  );

  /// Also the Firestore receipt id, so originals upload to their final path
  /// before the save and a retry overwrites rather than duplicates.
  final String id;

  /// Client-generated; the Function ignores a second save with the same key.
  final String saveKey;
  final ReceiptSource source;
  final DateTime createdAt;
  List<DraftPage> pages;
  List<DraftItem> items;
  String? shop;
  DateTime? purchaseDate;
  String currency;
  int? totalMinor;
  int? taxMinor;
  String? orderNumber;
  String? returnWording;

  /// Set only when the user confirms the wording or types a date.
  DateTime? returnDeadline;
  bool returnFromWording;
  String? checksum;
  String? ocrText;
  final Map<String, dynamic> extracted;
  bool sameForAll;
  Purpose sharedPurpose;
  String? sharedRoomId;
  String? sharedCarId;
  DraftState state;
  List<String> uploadedPaths;
  bool duplicateAcknowledged;
  String? lastError;

  int get itemsTotal => items.fold(0, (sum, i) => sum + i.value);

  /// Item lines can legitimately differ from the total (discounts,
  /// delivery), so a mismatch is surfaced, never blocked.
  bool get itemsMatchTotal =>
      items.isEmpty || totalMinor == null || itemsTotal == totalMinor;

  /// Applies "Same for all" values to every item.
  void applyShared() {
    if (!sameForAll) return;
    for (final item in items) {
      item.purpose = sharedPurpose;
      item.carId = sharedPurpose == Purpose.car ? sharedCarId : null;
      if (item.isPhysical && item.inHome && sharedRoomId != null) {
        item.setRoom(sharedRoomId);
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'saveKey': saveKey,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
    'pages': [for (final p in pages) p.toJson()],
    'items': [for (final i in items) i.toJson()],
    'shop': shop,
    'purchaseDate': purchaseDate == null ? null : Dates.toIso(purchaseDate!),
    'currency': currency,
    'totalMinor': totalMinor,
    'taxMinor': taxMinor,
    'orderNumber': orderNumber,
    'returnWording': returnWording,
    'returnDeadline': returnDeadline == null
        ? null
        : Dates.toIso(returnDeadline!),
    'returnFromWording': returnFromWording,
    'checksum': checksum,
    'ocrText': ocrText,
    'extracted': extracted,
    'sameForAll': sameForAll,
    'sharedPurpose': sharedPurpose.name,
    'sharedRoomId': sharedRoomId,
    'sharedCarId': sharedCarId,
    'state': state.name,
    'uploadedPaths': uploadedPaths,
    'duplicateAcknowledged': duplicateAcknowledged,
    'lastError': lastError,
  };
}
