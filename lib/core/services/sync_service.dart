import 'dart:async';
import 'dart:developer' as developer;
import '../../features/triage/domain/usecases/sync_pending_usecase.dart';
import 'connectivity_service.dart';

/// Coordinates background synchronisation of pending triage records.
///
/// Responsibilities:
///  - listens for connectivity changes and triggers a sync the moment the
///    device comes back online;
///  - exposes a [syncingStream] the UI can watch to show a "Syncing..."
///    indicator;
///  - guards against overlapping sync runs (`_isSyncing`), which is what
///    prevents duplicate uploads if connectivity flickers on/off quickly.
///
/// Depends on [SyncPendingUseCase] rather than the repository directly, so
/// this class contains no persistence or network details of its own - it
/// only orchestrates *when* a sync happens.
class SyncService {
  SyncService({
    required SyncPendingUseCase syncPendingUseCase,
    required ConnectivityService connectivityService,
  })  : _syncPendingUseCase = syncPendingUseCase,
        _connectivityService = connectivityService;

  final SyncPendingUseCase _syncPendingUseCase;
  final ConnectivityService _connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;
  final StreamController<bool> _syncingController =
      StreamController<bool>.broadcast();
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;

  /// Emits `true` while a sync run is in progress, `false` otherwise.
  Stream<bool> get syncingStream => _syncingController.stream;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// Begins listening for connectivity-restored events. Call once, e.g.
  /// when the relevant Riverpod provider is first read.
  void start() {
    _connectivitySubscription = _connectivityService.onlineStatus.listen(
      (isOnline) {
        if (isOnline) {
          unawaited(_runSync());
        }
      },
    );
  }

  /// Triggered from [AppLifecycleState.resumed] - if the app is brought to
  /// the foreground and the device happens to be online, immediately try
  /// to clear the pending queue rather than waiting for the next
  /// connectivity-change event.
  Future<void> attemptSyncOnResume() async {
    final isOnline = await _connectivityService.isOnlineNow();
    if (isOnline) {
      await _runSync();
    }
  }

  /// Exposed for a manual "Retry" button in the UI.
  Future<void> manualSync() => _runSync();

  Future<void> _runSync() async {
    if (_isSyncing) return; // prevents overlapping/duplicate sync runs
    _isSyncing = true;
    _syncingController.add(true);
    try {
      await _syncPendingUseCase.call();
      _lastSyncedAt = DateTime.now();
    } catch (e) {
      developer.log('Unexpected error during sync: $e', name: 'SyncService');
    } finally {
      _isSyncing = false;
      _syncingController.add(false);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncingController.close();
  }
}
