import 'product_category.dart';

// Models for the ownership roadmap (screens 53–98). These features are
// previews: data lives in memory only and is clearly labelled as sample data.

enum ItemCondition {
  asNew('New'),
  excellent('Excellent'),
  good('Good'),
  fair('Fair'),
  poor('Poor');

  const ItemCondition(this.label);

  final String label;
}

enum OwnershipStatus {
  owned('Owned'),
  sold('Sold'),
  gifted('Gifted'),
  disposed('Disposed'),
  lost('Lost or stolen');

  const OwnershipStatus(this.label);

  final String label;
}

class OwnedDocument {
  const OwnedDocument(this.title, this.detail, {this.missing = false});

  final String title;
  final String detail;
  final bool missing;
}

class OwnershipEvent {
  const OwnershipEvent({required this.label, required this.title, this.detail});

  /// Short badge text such as `12 Sep` or `Next`.
  final String label;
  final String title;
  final String? detail;
}

class Possession {
  const Possession({
    required this.id,
    required this.name,
    required this.room,
    this.brandModel,
    this.category = ProductCategory.other,
    this.purchasePrice,
    this.purchaseDate,
    this.retailer,
    this.condition = ItemCondition.good,
    this.status = OwnershipStatus.owned,
    this.serialNumber,
    this.modelNumber,
    this.receiptId,
    this.warrantyExpiry,
    this.warrantyTermsMissing = false,
    this.photos = const [],
    this.documents = const [],
    this.collection,
    this.events = const [],
    this.saleDate,
    this.salePrice,
    this.buyerNote,
  });

  final String id;
  final String name;
  final String room;
  final String? brandModel;
  final ProductCategory category;
  final int? purchasePrice;
  final DateTime? purchaseDate;
  final String? retailer;
  final ItemCondition condition;
  final OwnershipStatus status;
  final String? serialNumber;
  final String? modelNumber;
  final String? receiptId;
  final DateTime? warrantyExpiry;
  final bool warrantyTermsMissing;
  final List<String> photos;
  final List<OwnedDocument> documents;
  final String? collection;
  final List<OwnershipEvent> events;
  final DateTime? saleDate;
  final int? salePrice;

  /// Optional note kept with a sale, such as who bought the item.
  final String? buyerNote;

  bool get hasReceipt => receiptId != null;
  bool get hasPhoto => photos.isNotEmpty;
  bool get hasSerial => serialNumber?.isNotEmpty ?? false;
  bool get hasPurchaseDetails => purchasePrice != null && purchaseDate != null;

  Possession copyWith({
    String? name,
    String? room,
    String? brandModel,
    ProductCategory? category,
    int? purchasePrice,
    ItemCondition? condition,
    OwnershipStatus? status,
    String? serialNumber,
    String? modelNumber,
    List<String>? photos,
    List<OwnedDocument>? documents,
    String? collection,
    List<OwnershipEvent>? events,
    DateTime? saleDate,
    int? salePrice,
    String? buyerNote,
    DateTime? warrantyExpiry,
    bool clearSaleDate = false,
    bool clearSalePrice = false,
    bool clearBuyerNote = false,
  }) => Possession(
    id: id,
    name: name ?? this.name,
    room: room ?? this.room,
    brandModel: brandModel ?? this.brandModel,
    category: category ?? this.category,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    purchaseDate: purchaseDate,
    retailer: retailer,
    condition: condition ?? this.condition,
    status: status ?? this.status,
    serialNumber: serialNumber ?? this.serialNumber,
    modelNumber: modelNumber ?? this.modelNumber,
    receiptId: receiptId,
    warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
    warrantyTermsMissing: warrantyTermsMissing,
    photos: photos ?? this.photos,
    documents: documents ?? this.documents,
    collection: collection ?? this.collection,
    events: events ?? this.events,
    saleDate: clearSaleDate ? null : (saleDate ?? this.saleDate),
    salePrice: clearSalePrice ? null : (salePrice ?? this.salePrice),
    buyerNote: clearBuyerNote ? null : (buyerNote ?? this.buyerNote),
  );
}

class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.item,
    required this.work,
    required this.due,
    this.cost,
    this.nextDue,
    this.done = false,
  });

  final String id;
  final String item;
  final String work;
  final DateTime due;
  final int? cost;
  final DateTime? nextDue;
  final bool done;
}

class RepairRecord {
  const RepairRecord({
    required this.id,
    required this.item,
    required this.problem,
    required this.provider,
    required this.cost,
    required this.date,
  });

  final String id;
  final String item;
  final String problem;
  final String provider;
  final int cost;
  final DateTime date;
}

enum MemberRole {
  owner('Owner', 'full access'),
  adult('Adult member', 'manage items'),
  contributor('Contributor', 'add records'),
  viewer('View only', 'read records');

  const MemberRole(this.label, this.access);

  final String label;
  final String access;
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.role,
  });

  final String id;
  final String name;
  final int itemCount;
  final String role;
}

class HouseholdMember {
  const HouseholdMember({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.pending = false,
  });

  final String id;
  final String name;
  final String? email;
  final MemberRole role;
  final bool pending;
}

class ActivityEntry {
  const ActivityEntry(this.when, this.title, this.detail);

  final String when;
  final String title;
  final String detail;
}

enum BoxStatus {
  notPacked('Not packed'),
  packed('Packed'),
  inTransit('In transit'),
  delivered('Delivered');

  const BoxStatus(this.label);

  final String label;
}

class MovingBox {
  const MovingBox({
    required this.number,
    required this.room,
    required this.status,
    required this.items,
    required this.destination,
  });

  final int number;
  final String room;
  final BoxStatus status;
  final List<String> items;
  final String destination;

  MovingBox copyWith({BoxStatus? status}) => MovingBox(
    number: number,
    room: room,
    status: status ?? this.status,
    items: items,
    destination: destination,
  );
}

class InboxDraft {
  const InboxDraft(this.id, this.name, this.origin, this.note);

  final String id;
  final String name;
  final String origin;
  final String note;
}

class Appraisal {
  const Appraisal({
    required this.item,
    required this.appraiser,
    required this.value,
    required this.date,
  });

  final String item;
  final String appraiser;
  final int value;
  final DateTime date;
}

class ShareLink {
  const ShareLink({
    required this.record,
    required this.include,
    required this.expiresAt,
  });

  final String record;
  final String include;
  final DateTime expiresAt;
}

class ClaimDraft {
  const ClaimDraft({
    required this.incidentType,
    required this.incidentDate,
    required this.item,
    required this.notes,
  });

  final String incidentType;
  final DateTime incidentDate;
  final String item;
  final String notes;
}
