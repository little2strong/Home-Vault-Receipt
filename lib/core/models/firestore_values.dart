import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/dates.dart';

/// Small readers that tolerate missing or mistyped fields, so one bad
/// document never breaks a whole list.
abstract final class Fs {
  static String? str(Object? v) => v is String && v.isNotEmpty ? v : null;

  static int intOr(Object? v, [int fallback = 0]) =>
      v is int ? v : (v is num ? v.toInt() : fallback);

  static int? intOrNull(Object? v) => v is num ? v.toInt() : null;

  static bool boolOr(Object? v, [bool fallback = false]) =>
      v is bool ? v : fallback;

  static DateTime? date(Object? v) => v is String ? Dates.parseIso(v) : null;

  static DateTime? time(Object? v) => switch (v) {
    Timestamp t => t.toDate(),
    DateTime d => d,
    _ => null,
  };

  static List<String> strings(Object? v) => [
    if (v is List)
      for (final e in v)
        if (e is String) e,
  ];

  static Map<String, dynamic> map(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static Map<String, int> intMap(Object? v) => {
    if (v is Map)
      for (final e in v.entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
  };

  static String? iso(DateTime? d) => d == null ? null : Dates.toIso(d);
}
