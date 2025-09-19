import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider =
    StreamProvider.autoDispose<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  final controller = StreamController<ConnectivityResult>();

  final subscription = connectivity.onConnectivityChanged.listen((results) {
    if (results.isNotEmpty) {
      controller.add(results.first);
    }
  });

  ref.onDispose(() async {
    await subscription.cancel();
    await controller.close();
  });

  return controller.stream;
});
