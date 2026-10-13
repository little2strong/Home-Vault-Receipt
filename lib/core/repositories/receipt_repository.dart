import 'dart:convert';

import 'package:get/get.dart';

import '../error/app_exception.dart';
import '../models/receipt_filter.dart';
import '../models/receipt_model.dart';
import '../services/key_value_store.dart';
import '../utils/dates.dart';

/// Source of truth for receipts. Records are persisted locally on every
/// change; [receipts] is observable so every screen stays in sync.
///
/// Each account has its own vault on the device: [openVault] switches to the
/// signed-in user's records so a second account never sees the first's.
class ReceiptRepository {
  ReceiptRepository({
    required this._store,
    this._clock = DateTime.now,
    this._seed,
    String? userId = 'local',
  }) {
    openVault(userId);
  }

  static const storageKey = 'receipts.v2';

  /// The free pilot keeps up to 100 saved receipt records.
  static const pilotLimit = 100;

  final KeyValueStore _store;
  final Clock _clock;

  /// Sample records for a vault opened for the first time (debug builds).
  final List<Receipt> Function(DateTime today)? _seed;
  final _receipts = <Receipt>[].obs;
  String? _userId;

  /// Account whose records are loaded, or null when signed out.
  String? get userId => _userId;

  String get _key => '$storageKey.$_userId';

  /// Loads [userId]'s records, or empties the list when signed out.
  void openVault(String? userId) {
    _userId = userId;
    _receipts.clear();
    if (userId != null) _load();
  }

  /// Every record, including drafts and queued uploads.
  List<Receipt> get receipts => _receipts;

  DateTime get today => Dates.dateOnly(_clock());

  /// Confirmed records, newest purchase first.
  List<Receipt> get saved =>
      _receipts.where((r) => r.isSaved).toList()..sort(_newestFirst);

  /// Drafts, queued and failed uploads, newest first.
  List<Receipt> get pending =>
      _receipts.where((r) => !r.isSaved).toList()..sort(_newestFirst);

  List<Receipt> get drafts =>
      pending.where((r) => r.status == ReceiptStatus.draft).toList();

  int get savedCount => _receipts.where((r) => r.isSaved).length;

  bool get isAtPilotLimit => savedCount >= pilotLimit;

  Receipt? byId(String id) => _receipts.firstWhereOrNull((r) => r.id == id);

  List<Receipt> search(ReceiptFilter filter) =>
      saved.where((r) => filter.matches(r, today)).toList();

  /// Saved receipts whose confirmed return deadline is today or later,
  /// soonest first. [withinDays] narrows to deadlines "coming up".
  List<Receipt> openDeadlines({int? withinDays}) {
    final now = today;
    return saved.where((r) {
      final days = r.daysUntilReturn(now);
      return days != null &&
          days >= 0 &&
          (withinDays == null || days <= withinDays);
    }).toList()..sort((a, b) => a.returnDeadline!.compareTo(b.returnDeadline!));
  }

  /// A saved record that looks like the same purchase: same order reference,
  /// or same shop, day and total.
  Receipt? findDuplicate(Receipt candidate) {
    final ref = candidate.reference?.trim().toLowerCase() ?? '';
    return saved.firstWhereOrNull((r) {
      if (r.id == candidate.id) return false;
      if (ref.isNotEmpty && r.reference?.trim().toLowerCase() == ref) {
        return true;
      }
      return r.retailer.trim().toLowerCase() ==
              candidate.retailer.trim().toLowerCase() &&
          Dates.isSameDay(r.purchaseDate, candidate.purchaseDate) &&
          r.total == candidate.total &&
          r.currency == candidate.currency;
    });
  }

  /// Inserts or replaces by id. Never changes the save status by itself.
  /// A failed write rolls the in-memory list back, so a signed-out save cannot
  /// leave a receipt that vanishes on the next launch.
  Future<Receipt> upsert(Receipt receipt) async {
    if (_userId == null) throw const AppException('Sign in to save receipts.');
    final stamped = receipt.copyWith(
      purchaseDate: Dates.dateOnly(receipt.purchaseDate),
      returnDeadline: receipt.returnDeadline == null
          ? null
          : Dates.dateOnly(receipt.returnDeadline!),
      updatedAt: _clock(),
    );
    final previous = List<Receipt>.of(_receipts);
    final index = _receipts.indexWhere((r) => r.id == receipt.id);
    if (index == -1) {
      _receipts.add(stamped);
    } else {
      _receipts[index] = stamped;
    }
    try {
      await _persist();
    } on Object {
      _receipts.assignAll(previous);
      rethrow;
    }
    return stamped;
  }

  /// Marks a record as saved in the vault, enforcing the pilot limit for
  /// records that were not already saved.
  Future<Receipt> commit(Receipt receipt) async {
    final wasSaved = byId(receipt.id)?.isSaved ?? false;
    if (!wasSaved && isAtPilotLimit) throw const QuotaExceededException();
    return upsert(receipt.copyWith(status: ReceiptStatus.saved));
  }

  Future<void> delete(String id) async {
    if (_userId == null) throw const AppException('Sign in to save receipts.');
    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) throw const AppException('Receipt not found');
    final previous = List<Receipt>.of(_receipts);
    _receipts.removeAt(index);
    try {
      await _persist();
    } on Object {
      _receipts.assignAll(previous);
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    _receipts.clear();
    if (_userId != null) await _store.remove(_key);
  }

  static int _newestFirst(Receipt a, Receipt b) {
    final byDate = b.purchaseDate.compareTo(a.purchaseDate);
    return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
  }

  void _load() {
    final raw = _store.read(_key);
    if (raw == null) {
      final seed = _seed?.call(today) ?? const [];
      if (seed.isNotEmpty) {
        _receipts.assignAll(seed);
        _persist();
      }
      return;
    }
    try {
      _receipts.assignAll([
        for (final json in jsonDecode(raw) as List)
          Receipt.fromJson(json as Map<String, dynamic>),
      ]);
    } on Object {
      // A corrupt store must not brick the app. Start empty and keep the
      // raw value so it can be recovered.
      _store.write('$_key.corrupt', raw);
    }
  }

  Future<void> _persist() async {
    if (_userId == null) throw const AppException('Sign in to save receipts.');
    await _store.write(
      _key,
      jsonEncode([for (final r in _receipts) r.toJson()]),
    );
  }
}
