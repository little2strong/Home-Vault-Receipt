import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/receipt_draft.dart';

/// Drafts are kept on the device until the server confirms the save, so a
/// closed app or a dropped connection never loses a receipt.
class DraftStore {
  DraftStore([SharedPreferencesAsync? prefs]) : _given = prefs;

  final SharedPreferencesAsync? _given;
  late final SharedPreferencesAsync _prefs = _given ?? SharedPreferencesAsync();

  static String _key(String uid) => 'drafts_$uid';

  Future<Map<String, ReceiptDraft>> _read(String uid) async {
    final raw = await _prefs.getString(_key(uid));
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in map.entries)
          e.key: ReceiptDraft.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(String uid, Map<String, ReceiptDraft> drafts) =>
      _prefs.setString(
        _key(uid),
        jsonEncode({for (final e in drafts.entries) e.key: e.value.toJson()}),
      );

  Future<List<ReceiptDraft>> all(String uid) async {
    final list = (await _read(uid)).values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<ReceiptDraft?> get(String uid, String id) async =>
      (await _read(uid))[id];

  Future<void> save(String uid, ReceiptDraft draft) async {
    final drafts = await _read(uid);
    drafts[draft.id] = draft;
    await _write(uid, drafts);
  }

  Future<void> remove(String uid, String id) async {
    final drafts = await _read(uid);
    if (drafts.remove(id) != null) await _write(uid, drafts);
  }
}
