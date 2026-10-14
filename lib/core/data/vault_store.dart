import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/enums.dart';
import '../models/item.dart';
import '../models/receipt.dart';
import '../models/vault_models.dart';
import '../utils/dates.dart';
import 'auth_repository.dart';
import 'paths.dart';

/// Live, signed-in view of the user's vault. Every list here streams from
/// Firestore (with its offline cache), so screens are just views over it.
class VaultStore extends GetxService {
  VaultStore(this._auth, [FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final AuthRepository _auth;
  final FirebaseFirestore _db;

  final user = Rxn<User>();
  final profile = Rxn<UserProfile>();
  final items = <Item>[].obs;
  final receipts = <Receipt>[].obs;
  final rooms = <Room>[].obs;
  final cars = <Car>[].obs;
  final warranties = <Warranty>[].obs;
  final returns = <ReturnDeadline>[].obs;
  final exports = <ExportJob>[].obs;
  final stats = const SpendingStats().obs;

  /// False until the first snapshot of items and receipts has arrived.
  final loaded = false.obs;

  final _subs = <StreamSubscription<Object?>>[];
  StreamSubscription<User?>? _authSub;

  String? get uid => user.value?.uid;

  /// Completes once the first auth state is known.
  final ready = Completer<void>();

  @override
  void onInit() {
    super.onInit();
    _authSub = _auth.changes.listen((u) {
      final changed = u?.uid != user.value?.uid;
      user.value = u;
      if (changed) _bind(u?.uid);
      if (!ready.isCompleted) ready.complete();
    });
  }

  void _bind(String? uid) {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    loaded.value = false;
    profile.value = null;
    items.clear();
    receipts.clear();
    rooms.clear();
    cars.clear();
    warranties.clear();
    returns.clear();
    exports.clear();
    stats.value = const SpendingStats();
    if (uid == null) return;

    var gotItems = false, gotReceipts = false;
    void markLoaded() {
      if (gotItems && gotReceipts) loaded.value = true;
    }

    _subs
      ..add(
        _db.doc(Paths.user(uid)).snapshots().listen((s) {
          profile.value = UserProfile.fromMap(uid, s.data());
        }, onError: _ignore),
      )
      ..add(
        _db
            // Sorted on the client so an item missing a field never drops out.
            .collection(Paths.items(uid))
            .snapshots()
            .listen((s) {
              final list = [
                for (final d in s.docs) Item.fromMap(d.id, d.data()),
              ]..sort(_byPurchaseDesc);
              items.assignAll(list);
              gotItems = true;
              markLoaded();
            }, onError: _ignore),
      )
      ..add(
        _db
            .collection(Paths.receipts(uid))
            // Every saved receipt has confirmedAt; purchaseDate may be unknown.
            .orderBy('confirmedAt', descending: true)
            .snapshots()
            .listen((s) {
              receipts.assignAll(
                [for (final d in s.docs) Receipt.fromMap(d.id, d.data())]
                  ..sort(_receiptsDesc),
              );
              gotReceipts = true;
              markLoaded();
            }, onError: _ignore),
      )
      ..add(
        _db.collection(Paths.rooms(uid)).orderBy('order').snapshots().listen((
          s,
        ) {
          rooms.assignAll([
            for (final d in s.docs) Room.fromMap(d.id, d.data()),
          ]);
        }, onError: _ignore),
      )
      ..add(
        _db.collection(Paths.cars(uid)).orderBy('name').snapshots().listen((s) {
          cars.assignAll([for (final d in s.docs) Car.fromMap(d.id, d.data())]);
        }, onError: _ignore),
      )
      ..add(
        _db
            .collection(Paths.warranties(uid))
            .orderBy('endDate')
            .snapshots()
            .listen((s) {
              warranties.assignAll([
                for (final d in s.docs) Warranty.fromMap(d.id, d.data()),
              ]);
            }, onError: _ignore),
      )
      ..add(
        _db
            .collection(Paths.returns(uid))
            .orderBy('deadline')
            .snapshots()
            .listen((s) {
              returns.assignAll([
                for (final d in s.docs) ReturnDeadline.fromMap(d.id, d.data()),
              ]);
            }, onError: _ignore),
      )
      ..add(
        _db
            .collection(Paths.exports(uid))
            .orderBy('requestedAt', descending: true)
            .limit(20)
            .snapshots()
            .listen((s) {
              exports.assignAll([
                for (final d in s.docs) ExportJob.fromMap(d.id, d.data()),
              ]);
            }, onError: _ignore),
      )
      ..add(
        _db.doc(Paths.stats(uid)).snapshots().listen((s) {
          stats.value = SpendingStats.fromMap(s.data());
        }, onError: _ignore),
      );
  }

  static void _ignore(Object error) {}

  static int _receiptsDesc(Receipt a, Receipt b) {
    final da = a.purchaseDate ?? a.confirmedAt ?? DateTime(1900);
    final db = b.purchaseDate ?? b.confirmedAt ?? DateTime(1900);
    return db.compareTo(da);
  }

  static int _byPurchaseDesc(Item a, Item b) {
    final da = a.purchaseDate ?? a.createdAt ?? DateTime(1900);
    final db = b.purchaseDate ?? b.createdAt ?? DateTime(1900);
    return db.compareTo(da);
  }

  // ------------------------------------------------------------- lookups

  Item? item(String id) => items.firstWhereOrNull((i) => i.id == id);
  Receipt? receipt(String id) => receipts.firstWhereOrNull((r) => r.id == id);
  Room? room(String id) => rooms.firstWhereOrNull((r) => r.id == id);
  Car? car(String? id) =>
      id == null ? null : cars.firstWhereOrNull((c) => c.id == id);
  Warranty? warrantyFor(String itemId) =>
      warranties.firstWhereOrNull((w) => w.itemId == itemId);
  ReturnDeadline? returnFor(String receiptId) =>
      returns.firstWhereOrNull((r) => r.receiptId == receiptId);

  List<Item> itemsOnReceipt(String receiptId) =>
      items.where((i) => i.receiptId == receiptId).toList();

  /// Items in one room, including split quantities.
  List<Item> itemsInRoom(String roomId) => items
      .where((i) => i.inInventory && i.allocations.containsKey(roomId))
      .toList();

  List<Item> get inventory => items.where((i) => i.inInventory).toList();

  /// Totals per currency of what was paid for items in the home.
  Map<String, int> inventoryTotals([String? roomId]) {
    final totals = <String, int>{};
    for (final i in inventory) {
      if (roomId != null && !i.allocations.containsKey(roomId)) continue;
      final v = roomId == null ? i.value : i.valueInRoom(roomId);
      totals[i.currency] = (totals[i.currency] ?? 0) + v;
    }
    return totals;
  }

  /// Item count per room, counting each split share once in its room.
  int itemCountInRoom(String roomId) => itemsInRoom(roomId).length;

  List<Item> get highValueWithoutPhoto =>
      inventory.where((i) => i.highValue && i.photoCount == 0).toList();

  String roomLabel(Item item) {
    if (!item.isPhysical || !item.inHome) {
      return switch (item.purpose) {
        Purpose.car => [
          'Car',
          if (car(item.carId) != null) car(item.carId)!.name,
        ].join(' · '),
        _ =>
          item.type == ItemType.physical
              ? item.purpose.label
              : '${item.type.label} · ${item.purpose.label}',
      };
    }
    if (item.allocations.isEmpty) return 'No room yet';
    if (item.isSplit) {
      return item.allocations.keys
          .map((id) => room(id)?.name ?? 'Room')
          .join(' · ');
    }
    return room(item.allocations.keys.first)?.name ?? 'Room';
  }

  List<Warranty> warrantiesWith(WarrantyStatus status) {
    final today = DateTime.now();
    return warranties.where((w) => w.statusOn(today) == status).toList();
  }

  /// Warranties ending within three months and return deadlines still
  /// open, soonest first — the Home "Expiring soon" list.
  List<Object> get expiringSoon {
    final today = Dates.dateOnly(DateTime.now());
    final list = <(DateTime, Object)>[
      for (final w in warranties)
        if (w.statusOn(today) == WarrantyStatus.expiring) (w.endDate, w),
      for (final r in returns)
        if (r.isOpen(today) && r.daysLeft(today) <= 14) (r.deadline, r),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final e in list) e.$2];
  }

  @override
  void onClose() {
    _authSub?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
