import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// true when the phone has no network connection.
final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

bool _isOffline(List<ConnectivityResult> results) {
  return results.isEmpty ||
      results.every((result) => result == ConnectivityResult.none);
}

Future<void> startConnectivityWatch() async {
  _connectivitySub?.cancel();

  final connectivity = Connectivity();

  try {
    isOfflineNotifier.value = _isOffline(
      await connectivity.checkConnectivity(),
    );
  } catch (e) {
    debugPrint('Connectivity check failed: $e');
  }

  _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
    isOfflineNotifier.value = _isOffline(results);
  });
}
