abstract final class Ids {
  static int _counter = 0;

  /// Unique within this install, even when called in a tight loop.
  static String next([String prefix = '']) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}${_counter++}';
}
