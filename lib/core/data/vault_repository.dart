import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/enums.dart';
import '../models/receipt.dart';
import '../models/vault_models.dart';
import '../services/firebase_bootstrap.dart';
import '../utils/dates.dart';
import 'file_store.dart';
import 'paths.dart';

class SaveResult {
  const SaveResult({
    required this.receiptId,
    required this.number,
    required this.itemIds,
    this.alreadySaved = false,
  });

  final String receiptId;
  final String number;
  final List<String> itemIds;

  /// True when the Function found this saveKey and did nothing.
  final bool alreadySaved;
}

/// A save that failed because the device is offline or the call timed out.
/// The draft is kept and retried.
class ConnectionFailure implements Exception {
  const ConnectionFailure();

  @override
  String toString() => 'Waiting for connection';
}

class VaultFailure implements Exception {
  const VaultFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Writes to the vault. Trusted fields (receipt numbers, totals, upload
/// times, deletions of files) go through Cloud Functions; the rest is
/// written directly under the owner-only rules.
class VaultRepository {
  VaultRepository({
    required this._uid,
    required this.files,
    FirebaseFirestore? db,
    FirebaseFunctions? functions,
  }) : _db = db ?? FirebaseFirestore.instance,
       _functionsOverride = functions;

  final String Function() _uid;
  final FirebaseFirestore _db;
  final FirebaseFunctions? _functionsOverride;
  final FileStore files;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseBootstrap.functions;

  String get uid => _uid();

  String newId(String collection) =>
      _db.collection('users/$uid/$collection').doc().id;

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final result = await _functions
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call<Object?>(data);
      final value = result.data;
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'internal' && (e.message ?? '').contains('network')) {
        throw const ConnectionFailure();
      }
      throw VaultFailure(e.message ?? 'Something went wrong. Try again.');
    }
  }

  // ------------------------------------------------------------ profile

  /// Creates the profile on first sign-in if the Function has not yet.
  Future<void> ensureProfile({
    String? displayName,
    String? email,
    String? timezone,
  }) async {
    final ref = _db.doc(Paths.user(uid));
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'displayName': displayName,
        'email': email,
        'timezone': timezone ?? 'Europe/London',
        'locale': 'en_GB',
        'mainCurrency': 'GBP',
        'reminderMinutes': 9 * 60,
        'warrantyReminders': true,
        'returnReminders': true,
        'keepPhotoLocation': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final data = snap.data() ?? {};
    final patch = <String, dynamic>{
      if (data['displayName'] == null && displayName != null)
        'displayName': displayName,
      if (data['email'] == null && email != null) 'email': email,
      if (timezone != null && data['timezone'] != timezone)
        'timezone': timezone,
    };
    if (patch.isNotEmpty) await ref.update(patch);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) =>
      _db.doc(Paths.user(uid)).set(fields, SetOptions(merge: true));

  Future<void> registerDevice(String token, String platform, String timezone) =>
      _db.doc('${Paths.devices(uid)}/$token').set({
        'platform': platform,
        'timezone': timezone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ----------------------------------------------------------- receipts

  /// One call writes the receipt and all its items in one batch, assigns
  /// the HV number and ignores a repeated [saveKey].
  Future<SaveResult> saveReceipt(Map<String, dynamic> payload) async {
    final data = await _call('saveReceipt', payload);
    return SaveResult(
      receiptId: data['receiptId'] as String,
      number: data['number'] as String,
      itemIds: [for (final id in data['itemIds'] as List? ?? []) '$id'],
      alreadySaved: data['alreadySaved'] == true,
    );
  }

  /// Receipts that look like this one: same file, or same shop, date and
  /// total. The user decides; nothing is merged automatically.
  Future<Receipt?> findDuplicate({
    String? checksum,
    String? shop,
    DateTime? purchaseDate,
    int? totalMinor,
  }) async {
    final col = _db.collection(Paths.receipts(uid));
    try {
      if (checksum != null) {
        final byFile = await col
            .where('checksum', isEqualTo: checksum)
            .limit(1)
            .get();
        if (byFile.docs.isNotEmpty) {
          final d = byFile.docs.first;
          return Receipt.fromMap(d.id, d.data());
        }
      }
      if (shop == null || purchaseDate == null || totalMinor == null) {
        return null;
      }
      final same = await col
          .where('purchaseDate', isEqualTo: Dates.toIso(purchaseDate))
          .where('totalMinor', isEqualTo: totalMinor)
          .limit(5)
          .get();
      for (final d in same.docs) {
        final r = Receipt.fromMap(d.id, d.data());
        if ((r.shop ?? '').toLowerCase().trim() == shop.toLowerCase().trim()) {
          return r;
        }
      }
    } on FirebaseException {
      // Offline: no warning rather than a false one.
    }
    return null;
  }

  /// Corrections to confirmed receipt details. Item copies of shop and
  /// date are kept in step by a Function.
  Future<void> updateReceipt(String id, Map<String, dynamic> fields) =>
      _db.doc('${Paths.receipts(uid)}/$id').update({
        ...fields,
        'revision': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteReceipt(String id) =>
      _call('deleteReceipt', {'receiptId': id});

  Future<void> setReturnDeadline({
    required String receiptId,
    required DateTime deadline,
    String? shop,
    String? label,
    String? sourceText,
  }) => _db.doc('${Paths.returns(uid)}/$receiptId').set({
    'deadline': Dates.toIso(deadline),
    'shop': shop,
    'label': label,
    'sourceText': sourceText,
    'confirmedAt': FieldValue.serverTimestamp(),
  });

  Future<void> clearReturnDeadline(String receiptId) =>
      _db.doc('${Paths.returns(uid)}/$receiptId').delete();

  // -------------------------------------------------------------- items

  Future<void> updateItem(String id, Map<String, dynamic> fields) => _db
      .doc('${Paths.items(uid)}/$id')
      .update({...fields, 'updatedAt': FieldValue.serverTimestamp()});

  /// Older belongings: name, room and a photo or estimated price.
  Future<String> addItemWithoutReceipt({
    required String name,
    required Category category,
    required String roomId,
    required int quantity,
    required String currency,
    int? estimateMinor,
    int? yearBought,
    String? itemId,
  }) async {
    final id = itemId ?? newId('items');
    await _db.doc('${Paths.items(uid)}/$id').set({
      'name': name.trim(),
      'category': category.name,
      'type': ItemType.physical.name,
      'purpose': Purpose.home.name,
      'inHome': true,
      'allocations': {roomId: quantity},
      'roomIds': [roomId],
      'quantity': quantity,
      'unitPriceMinor': estimateMinor == null || quantity == 0
          ? null
          : estimateMinor ~/ quantity,
      'lineTotalMinor': estimateMinor,
      'currency': currency,
      'status': ItemStatus.owned.name,
      'highValue': false,
      'estimated': true,
      'yearBought': yearBought,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> setAllocations(String itemId, Map<String, int> allocations) =>
      updateItem(itemId, {
        'allocations': allocations,
        'roomIds': allocations.keys.toList(),
      });

  Future<void> deleteItem(String id) => _call('deleteItem', {'itemId': id});

  // --------------------------------------------------------- warranties

  Future<void> saveWarranty({
    required String itemId,
    required DateTime endDate,
    int? lengthMonths,
    String? itemName,
    String? shop,
    DateTime? purchaseDate,
    bool remind3Months = true,
    bool remind2Weeks = true,
    String? cardPhotoPath,
  }) async {
    final batch = _db.batch()
      ..set(_db.doc('${Paths.warranties(uid)}/$itemId'), {
        'itemId': itemId,
        'endDate': Dates.toIso(endDate),
        'lengthMonths': lengthMonths,
        'itemName': itemName,
        'shop': shop,
        'purchaseDate': purchaseDate == null ? null : Dates.toIso(purchaseDate),
        'remind3Months': remind3Months,
        'remind2Weeks': remind2Weeks,
        'cardPhotoPath': ?cardPhotoPath,
        'confirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
      ..update(_db.doc('${Paths.items(uid)}/$itemId'), {
        'warrantyEnd': Dates.toIso(endDate),
      });
    await batch.commit();
  }

  Future<void> deleteWarranty(String itemId) async {
    final batch = _db.batch()
      ..delete(_db.doc('${Paths.warranties(uid)}/$itemId'))
      ..update(_db.doc('${Paths.items(uid)}/$itemId'), {'warrantyEnd': null});
    await batch.commit();
  }

  Future<String> uploadWarrantyCard(String itemId, Uint8List jpeg) async {
    final path = Paths.warrantyCard(uid, itemId);
    await files.put(path, jpeg, contentType: 'image/jpeg');
    return path;
  }

  // ------------------------------------------------------------- photos

  Stream<List<ItemPhoto>> photos(String itemId) => _db
      .collection(Paths.photos(uid, itemId))
      .orderBy('createdAt')
      .snapshots()
      .map((s) => [for (final d in s.docs) ItemPhoto.fromMap(d.id, d.data())]);

  /// Writes the evidence record, then uploads the file. A Function adds the
  /// server upload time and the thumbnail once the file arrives.
  Future<void> addPhoto({
    required String itemId,
    required Uint8List jpeg,
    required PhotoSource source,
    required String sha256,
    required bool gpsKept,
    DateTime? deviceTakenAt,
    String? label,
    void Function(double)? onProgress,
  }) async {
    final ref = _db.collection(Paths.photos(uid, itemId)).doc();
    final path = Paths.photo(uid, itemId, ref.id);
    await ref.set({
      'path': path,
      'source': source.name,
      'deviceTakenAt': deviceTakenAt == null
          ? null
          : Timestamp.fromDate(deviceTakenAt),
      'sha256': sha256,
      'gpsKept': gpsKept,
      'label': label,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await files.put(
      path,
      jpeg,
      contentType: 'image/jpeg',
      metadata: {'sha256': sha256, 'photoId': ref.id},
      onProgress: onProgress,
    );
  }

  Future<void> labelPhoto(String itemId, String photoId, String? label) =>
      _db.doc('${Paths.photos(uid, itemId)}/$photoId').update({'label': label});

  Future<void> deletePhoto(String itemId, String photoId) =>
      _call('deletePhoto', {'itemId': itemId, 'photoId': photoId});

  // -------------------------------------------------------------- rooms

  Future<void> createRooms(List<({RoomType type, String name})> rooms) async {
    final batch = _db.batch();
    final existing = await _db.collection(Paths.rooms(uid)).count().get();
    var order = existing.count ?? 0;
    for (final r in rooms) {
      batch.set(_db.collection(Paths.rooms(uid)).doc(), {
        'type': r.type.name,
        'name': r.name,
        'order': order++,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(_db.doc(Paths.user(uid)), {
      'homeSetupDone': true,
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> renameRoom(String roomId, String name) =>
      _db.doc('${Paths.rooms(uid)}/$roomId').update({'name': name.trim()});

  Future<void> deleteRoom(String roomId) =>
      _call('deleteRoom', {'roomId': roomId});

  Future<void> uploadRoomVideo({
    required String roomId,
    required Uint8List mp4,
    required int seconds,
    void Function(double)? onProgress,
  }) async {
    final path = Paths.roomVideo(uid, roomId);
    await files.put(
      path,
      mp4,
      contentType: 'video/mp4',
      metadata: {'seconds': '$seconds'},
      onProgress: onProgress,
    );
    await _db.doc('${Paths.rooms(uid)}/$roomId').update({
      'videoPath': path,
      'videoSeconds': seconds,
    });
  }

  Future<void> deleteRoomVideo(String roomId) =>
      _call('deleteRoomVideo', {'roomId': roomId});

  // --------------------------------------------------------------- cars

  Future<String> saveCar({
    String? id,
    required String name,
    String? reg,
  }) async {
    final ref = id == null
        ? _db.collection(Paths.cars(uid)).doc()
        : _db.doc('${Paths.cars(uid)}/$id');
    await ref.set({
      'name': name.trim(),
      'reg': (reg?.trim().isEmpty ?? true) ? null : reg!.trim().toUpperCase(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  Future<void> deleteCar(String id) =>
      _db.doc('${Paths.cars(uid)}/$id').delete();

  // ------------------------------------------------------------ exports

  /// Created by the app, filled by a Function, link valid for 24 hours.
  Future<String> requestExport({
    required ExportKind kind,
    required ExportFormat format,
    bool includePhotos = true,
    bool includeReceiptNumbers = true,
    bool includeWithoutReceipts = true,
    DateTime? from,
    Purpose? purpose,
  }) async {
    final ref = _db.collection(Paths.exports(uid)).doc();
    await ref.set({
      'kind': kind.name,
      'format': format.name,
      'status': ExportStatus.building.name,
      'filters': {
        'includePhotos': includePhotos,
        'includeReceiptNumbers': includeReceiptNumbers,
        'includeWithoutReceipts': includeWithoutReceipts,
        'from': from == null ? null : Dates.toIso(from),
        'purpose': purpose?.name,
      },
      'requestedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<ExportJob?> export(String id) => _db
      .doc('${Paths.exports(uid)}/$id')
      .snapshots()
      .map((s) => s.exists ? ExportJob.fromMap(s.id, s.data()!) : null);

  // ------------------------------------------------------------ account

  /// Deletes Firestore data, files, exports and the sign-in itself.
  Future<void> deleteAccount() =>
      _call('deleteAccount', {}, timeout: const Duration(minutes: 5));
}
