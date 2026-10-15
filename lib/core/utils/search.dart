/// Word-prefix matching used by Search (07) and Products.
/// Mirrors the server's lowercase `searchTokens`.
abstract final class SearchText {
  static final _split = RegExp(r"[^a-z0-9£€$'&]+");

  static List<String> words(String text) => text
      .toLowerCase()
      .replaceAll('"', ' ')
      .split(_split)
      .where((w) => w.isNotEmpty)
      .toList();

  /// True when every query word starts some word in [fields].
  static bool matches(String query, Iterable<String?> fields) {
    final q = words(query);
    if (q.isEmpty) return false;
    final haystack = [
      for (final f in fields)
        if (f != null) ...words(f),
    ];
    return q.every((term) => haystack.any((w) => w.startsWith(term)));
  }

  /// Every prefix of every word, for Firestore `array-contains` queries.
  static List<String> tokens(Iterable<String?> fields, {int maxLength = 20}) {
    final out = <String>{};
    for (final f in fields) {
      if (f == null) continue;
      for (final w in words(f)) {
        final limit = w.length < maxLength ? w.length : maxLength;
        for (var i = 1; i <= limit; i++) {
          out.add(w.substring(0, i));
        }
      }
    }
    return out.toList()..sort();
  }
}
