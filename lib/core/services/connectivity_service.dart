import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Drives the "Waiting for connection" banner and retries of saved drafts.
class ConnectivityService extends GetxService {
  final online = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final c = Connectivity();
    c.checkConnectivity().then(_update).catchError((_) {});
    _sub = c.onConnectivityChanged.listen(_update, onError: (_) {});
  }

  void _update(List<ConnectivityResult> results) {
    online.value = results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
