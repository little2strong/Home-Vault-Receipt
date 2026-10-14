import '../utils/dates.dart';
import 'enums.dart';
import 'firestore_values.dart';

class Room {
  const Room({
    required this.id,
    required this.type,
    required this.name,
    this.order = 0,
    this.videoPath,
    this.videoUploadedAt,
    this.videoSeconds,
  });

  factory Room.fromMap(String id, Map<String, dynamic> m) => Room(
    id: id,
    type: RoomType.fromName(Fs.str(m['type'])),
    name: Fs.str(m['name']) ?? 'Room',
    order: Fs.intOr(m['order']),
    videoPath: Fs.str(m['videoPath']),
    videoUploadedAt: Fs.time(m['videoUploadedAt']),
    videoSeconds: Fs.intOrNull(m['videoSeconds']),
  );

  final String id;
  final RoomType type;
  final String name;
  final int order;
  final String? videoPath;
  final DateTime? videoUploadedAt;
  final int? videoSeconds;

  bool get hasVideo => videoPath != null;
}

class Car {
  const Car({required this.id, required this.name, this.reg});

  factory Car.fromMap(String id, Map<String, dynamic> m) =>
      Car(id: id, name: Fs.str(m['name']) ?? 'Car', reg: Fs.str(m['reg']));

  final String id;
  final String name;
  final String? reg;
}

/// Keyed by item; one warranty per item. Only ever from an end date or
/// length the user confirmed.
class Warranty {
  const Warranty({
    required this.itemId,
    required this.endDate,
    this.itemName,
    this.shop,
    this.purchaseDate,
    this.lengthMonths,
    this.cardPhotoPath,
    this.remindMonthsBefore = true,
    this.remindWeeksBefore = true,
    this.confirmedAt,
  });

  factory Warranty.fromMap(String id, Map<String, dynamic> m) => Warranty(
    itemId: id,
    endDate: Fs.date(m['endDate']) ?? DateTime(2000),
    itemName: Fs.str(m['itemName']),
    shop: Fs.str(m['shop']),
    purchaseDate: Fs.date(m['purchaseDate']),
    lengthMonths: Fs.intOrNull(m['lengthMonths']),
    cardPhotoPath: Fs.str(m['cardPhotoPath']),
    remindMonthsBefore: Fs.boolOr(m['remind3Months'], true),
    remindWeeksBefore: Fs.boolOr(m['remind2Weeks'], true),
    confirmedAt: Fs.time(m['confirmedAt']),
  );

  /// Lists split at three months.
  static const expiringWindowMonths = 3;

  final String itemId;
  final DateTime endDate;
  final String? itemName;
  final String? shop;
  final DateTime? purchaseDate;
  final int? lengthMonths;
  final String? cardPhotoPath;
  final bool remindMonthsBefore;
  final bool remindWeeksBefore;
  final DateTime? confirmedAt;

  WarrantyStatus statusOn(DateTime today) {
    final day = Dates.dateOnly(today);
    if (endDate.isBefore(day)) return WarrantyStatus.expired;
    if (!endDate.isAfter(Dates.addMonths(day, expiringWindowMonths))) {
      return WarrantyStatus.expiring;
    }
    return WarrantyStatus.active;
  }

  int daysLeft(DateTime today) => Dates.daysBetween(today, endDate);

  /// Default reminders: 3 months and 2 weeks before the end date.
  static DateTime threeMonthsBefore(DateTime end) => Dates.addMonths(end, -3);
  static DateTime twoWeeksBefore(DateTime end) => Dates.addDays(end, -14);
}

/// Only from receipt wording the user confirmed or a date the user typed.
class ReturnDeadline {
  const ReturnDeadline({
    required this.receiptId,
    required this.deadline,
    this.shop,
    this.label,
    this.sourceText,
    this.confirmedAt,
  });

  factory ReturnDeadline.fromMap(String id, Map<String, dynamic> m) =>
      ReturnDeadline(
        receiptId: id,
        deadline: Fs.date(m['deadline']) ?? DateTime(2000),
        shop: Fs.str(m['shop']),
        label: Fs.str(m['label']),
        sourceText: Fs.str(m['sourceText']),
        confirmedAt: Fs.time(m['confirmedAt']),
      );

  final String receiptId;
  final DateTime deadline;
  final String? shop;

  /// e.g. `Wool coat`
  final String? label;

  /// The returns sentence the user confirmed, or null for a typed date.
  final String? sourceText;
  final DateTime? confirmedAt;

  int daysLeft(DateTime today) => Dates.daysBetween(today, deadline);
  bool isOpen(DateTime today) => daysLeft(today) >= 0;
}

/// Evidence record per photo. [serverUploadedAt] is written by a Function,
/// never by the app.
class ItemPhoto {
  const ItemPhoto({
    required this.id,
    required this.path,
    required this.source,
    this.thumbPath,
    this.label,
    this.deviceTakenAt,
    this.serverUploadedAt,
    this.sha256,
    this.gpsKept = false,
  });

  factory ItemPhoto.fromMap(String id, Map<String, dynamic> m) => ItemPhoto(
    id: id,
    path: Fs.str(m['path']) ?? '',
    source: PhotoSource.fromName(Fs.str(m['source'])),
    thumbPath: Fs.str(m['thumbPath']),
    label: Fs.str(m['label']),
    deviceTakenAt: Fs.time(m['deviceTakenAt']),
    serverUploadedAt: Fs.time(m['serverUploadedAt']),
    sha256: Fs.str(m['sha256']),
    gpsKept: Fs.boolOr(m['gpsKept']),
  );

  final String id;
  final String path;
  final String? thumbPath;
  final PhotoSource source;
  final String? label;
  final DateTime? deviceTakenAt;
  final DateTime? serverUploadedAt;
  final String? sha256;
  final bool gpsKept;

  /// `In-app camera · 14 Sep 2026` — honest provenance, never "verified".
  String get provenance {
    final when = deviceTakenAt ?? serverUploadedAt;
    return when == null
        ? source.label
        : '${source.label} · ${when.day} ${_months[when.month - 1]} ${when.year}';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

/// Per-currency totals, written only by Functions from confirmed receipts.
class SpendingStats {
  const SpendingStats({
    this.last30Days = const {},
    this.last365Days = const {},
    this.lifetime = const {},
    this.receipts30 = 0,
    this.receipts365 = 0,
    this.receiptsLifetime = 0,
    this.byCategory365 = const {},
    this.byPurpose365 = const {},
    this.byCategory30 = const {},
    this.byPurpose30 = const {},
    this.byCategoryLifetime = const {},
    this.byPurposeLifetime = const {},
    this.cars = const {},
    this.firstPurchase,
    this.updatedAt,
  });

  factory SpendingStats.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const SpendingStats();
    Map<String, Map<String, int>> nested(Object? v) => {
      if (v is Map)
        for (final e in v.entries) '${e.key}': Fs.intMap(e.value),
    };
    return SpendingStats(
      last30Days: Fs.intMap(m['last30Days']),
      last365Days: Fs.intMap(m['last365Days']),
      lifetime: Fs.intMap(m['lifetime']),
      receipts30: Fs.intOr(m['receipts30']),
      receipts365: Fs.intOr(m['receipts365']),
      receiptsLifetime: Fs.intOr(m['receiptsLifetime']),
      byCategory30: nested(m['byCategory30']),
      byPurpose30: nested(m['byPurpose30']),
      byCategory365: nested(m['byCategory365']),
      byPurpose365: nested(m['byPurpose365']),
      byCategoryLifetime: nested(m['byCategoryLifetime']),
      byPurposeLifetime: nested(m['byPurposeLifetime']),
      cars: {
        if (m['cars'] is Map)
          for (final e in (m['cars'] as Map).entries)
            '${e.key}': CarSpend.fromMap(Fs.map(e.value)),
      },
      firstPurchase: Fs.date(m['firstPurchase']),
      updatedAt: Fs.time(m['updatedAt']),
    );
  }

  final Map<String, int> last30Days;
  final Map<String, int> last365Days;
  final Map<String, int> lifetime;
  final int receipts30;
  final int receipts365;
  final int receiptsLifetime;

  /// currency → category name → minor units.
  final Map<String, Map<String, int>> byCategory30;
  final Map<String, Map<String, int>> byPurpose30;
  final Map<String, Map<String, int>> byCategory365;
  final Map<String, Map<String, int>> byPurpose365;
  final Map<String, Map<String, int>> byCategoryLifetime;
  final Map<String, Map<String, int>> byPurposeLifetime;
  final Map<String, CarSpend> cars;
  final DateTime? firstPurchase;
  final DateTime? updatedAt;
}

class CarSpend {
  const CarSpend({
    this.last30Days = const {},
    this.last365Days = const {},
    this.itemCount = 0,
  });

  factory CarSpend.fromMap(Map<String, dynamic> m) => CarSpend(
    last30Days: Fs.intMap(m['last30Days']),
    last365Days: Fs.intMap(m['last365Days']),
    itemCount: Fs.intOr(m['itemCount']),
  );

  final Map<String, int> last30Days;
  final Map<String, int> last365Days;
  final int itemCount;
}

class ExportJob {
  const ExportJob({
    required this.id,
    required this.kind,
    required this.format,
    required this.status,
    this.requestedAt,
    this.expiresAt,
    this.sizeBytes,
    this.itemCount,
    this.roomCount,
    this.url,
    this.paths = const [],
    this.error,
    this.includePhotos = true,
    this.includeReceiptNumbers = true,
    this.includeWithoutReceipts = true,
  });

  factory ExportJob.fromMap(String id, Map<String, dynamic> m) {
    final filters = Fs.map(m['filters']);
    return ExportJob(
      id: id,
      kind: ExportKind.fromName(Fs.str(m['kind'])),
      format: ExportFormat.fromName(Fs.str(m['format'])),
      status: ExportStatus.fromName(Fs.str(m['status'])),
      requestedAt: Fs.time(m['requestedAt']),
      expiresAt: Fs.time(m['expiresAt']),
      sizeBytes: Fs.intOrNull(m['sizeBytes']),
      itemCount: Fs.intOrNull(m['itemCount']),
      roomCount: Fs.intOrNull(m['roomCount']),
      url: Fs.str(m['url']),
      paths: Fs.strings(m['paths']),
      error: Fs.str(m['error']),
      includePhotos: Fs.boolOr(filters['includePhotos'], true),
      includeReceiptNumbers: Fs.boolOr(filters['includeReceiptNumbers'], true),
      includeWithoutReceipts: Fs.boolOr(
        filters['includeWithoutReceipts'],
        true,
      ),
    );
  }

  final String id;
  final ExportKind kind;
  final ExportFormat format;
  final ExportStatus status;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final int? sizeBytes;
  final int? itemCount;
  final int? roomCount;

  /// Short-lived signed link created by the Function.
  final String? url;
  final List<String> paths;
  final String? error;
  final bool includePhotos;
  final bool includeReceiptNumbers;
  final bool includeWithoutReceipts;

  bool isExpired(DateTime now) =>
      status == ExportStatus.expired ||
      (expiresAt != null && expiresAt!.isBefore(now));

  bool isReady(DateTime now) => status == ExportStatus.ready && !isExpired(now);
}

class UserProfile {
  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.timezone = 'Europe/London',
    this.mainCurrency = 'GBP',
    this.reminderMinutes = 9 * 60,
    this.warrantyReminders = true,
    this.returnReminders = true,
    this.keepPhotoLocation = false,
    this.homeSetupDone = false,
    this.notificationsAsked = false,
    this.receiptCounter = 0,
    this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic>? m) {
    m ??= const {};
    return UserProfile(
      uid: uid,
      displayName: Fs.str(m['displayName']),
      email: Fs.str(m['email']),
      timezone: Fs.str(m['timezone']) ?? 'Europe/London',
      mainCurrency: Fs.str(m['mainCurrency']) ?? 'GBP',
      reminderMinutes: Fs.intOr(m['reminderMinutes'], 9 * 60),
      warrantyReminders: Fs.boolOr(m['warrantyReminders'], true),
      returnReminders: Fs.boolOr(m['returnReminders'], true),
      keepPhotoLocation: Fs.boolOr(m['keepPhotoLocation']),
      homeSetupDone: Fs.boolOr(m['homeSetupDone']),
      notificationsAsked: Fs.boolOr(m['notificationsAsked']),
      receiptCounter: Fs.intOr(m['receiptCounter']),
      createdAt: Fs.time(m['createdAt']),
    );
  }

  final String uid;
  final String? displayName;
  final String? email;
  final String timezone;
  final String mainCurrency;

  /// Minutes after midnight in [timezone]; 09:00 by default.
  final int reminderMinutes;
  final bool warrantyReminders;
  final bool returnReminders;
  final bool keepPhotoLocation;
  final bool homeSetupDone;
  final bool notificationsAsked;
  final int receiptCounter;
  final DateTime? createdAt;

  String get firstName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  String get initial {
    final source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (email ?? '?');
    return source.isEmpty ? '?' : source.substring(0, 1).toUpperCase();
  }
}
