import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../data/datasources/mock_api_service.dart';
import '../../data/datasources/triage_local_datasource.dart';
import '../../data/models/triage_record_model.dart';
import '../../data/repositories/triage_repository_impl.dart';
import '../../domain/entities/triage_record.dart';
import '../../domain/repositories/triage_repository.dart';
import '../../domain/usecases/get_all_usecase.dart';
import '../../domain/usecases/get_pending_usecase.dart';
import '../../domain/usecases/save_triage_usecase.dart';
import '../../domain/usecases/sync_pending_usecase.dart';

/// Overridden in `main.dart` once the Hive box has been opened. Kept as a
/// throwing default so misuse (forgetting the override) fails loudly
/// instead of silently misbehaving.
final hiveBoxProvider = Provider<Box<TriageRecordModel>>((ref) {
  throw UnimplementedError(
    'hiveBoxProvider must be overridden with the opened Hive box in main.dart',
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final mockApiServiceProvider = Provider<MockApiService>((ref) {
  return MockApiService();
});

final triageLocalDataSourceProvider = Provider<TriageLocalDataSource>((ref) {
  final box = ref.watch(hiveBoxProvider);
  return TriageLocalDataSourceImpl(box);
});

/// The single, app-wide entry point for triage data access. Presentation
/// code and use cases depend on the [TriageRepository] interface only.
final triageRepositoryProvider = Provider<TriageRepository>((ref) {
  return TriageRepositoryImpl(
    localDataSource: ref.watch(triageLocalDataSourceProvider),
    apiService: ref.watch(mockApiServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

final getAllUseCaseProvider = Provider<GetAllUseCase>((ref) {
  return GetAllUseCase(ref.watch(triageRepositoryProvider));
});

final saveTriageUseCaseProvider = Provider<SaveTriageUseCase>((ref) {
  return SaveTriageUseCase(ref.watch(triageRepositoryProvider));
});

final getPendingUseCaseProvider = Provider<GetPendingUseCase>((ref) {
  return GetPendingUseCase(ref.watch(triageRepositoryProvider));
});

final syncPendingUseCaseProvider = Provider<SyncPendingUseCase>((ref) {
  return SyncPendingUseCase(ref.watch(triageRepositoryProvider));
});

/// Starts listening for connectivity-restored events as soon as it is
/// first read (see [SyncService.start]), and cleans up on disposal.
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    syncPendingUseCase: ref.watch(syncPendingUseCaseProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive online/offline signal for the UI (e.g. the "Waiting for
/// Network" banner).
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onlineStatus;
});

/// Reactive syncing-in-progress signal for the UI (e.g. the "Syncing..."
/// indicator).
final syncingStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncServiceProvider).syncingStream;
});

/// All submitted records, most recent first, for the list beneath the
/// form. Call `ref.invalidate(allRecordsProvider)` after a submit or a
/// sync completes to refresh this list.
final allRecordsProvider = FutureProvider.autoDispose<List<TriageRecord>>((ref) async {
  return ref.watch(getAllUseCaseProvider).call();
});

/// Convenience derived count of pending (not-yet-synced) records, used for
/// the pending-count badge.
final pendingCountProvider = Provider.autoDispose<int>((ref) {
  final recordsAsync = ref.watch(allRecordsProvider);
  return recordsAsync.maybeWhen(
    data: (records) => records.where((r) => !r.isSynced).length,
    orElse: () => 0,
  );
});
