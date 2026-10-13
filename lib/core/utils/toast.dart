import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Short confirmations. Uses the app's [ScaffoldMessenger] rather than
/// `Get.snackbar`, because an open Get snackbar makes `Get.back()` close the
/// snackbar instead of the page.
abstract final class Toast {
  static void show(String message) {
    final context = Get.context;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
