import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around [Connectivity] exposing a simple boolean
/// online/offline signal, both as a one-off check and as a stream.
///
/// Isolating this behind a service (rather than using connectivity_plus
/// directly in the repository/UI) keeps the rest of the app decoupled from
/// the specific plugin API, and makes it easy to fake in tests.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` whenever the device has some form of network reachability
  /// and `false` when it has none (e.g. Airplane Mode).
  Stream<bool> get onlineStatus => _connectivity.onConnectivityChanged
      .map((results) => _hasConnection(results));

  /// One-off check of current connectivity, used before attempting an
  /// upload or a lifecycle-triggered sync.
  Future<bool> isOnlineNow() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
