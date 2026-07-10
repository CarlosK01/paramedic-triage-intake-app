import 'package:flutter_test/flutter_test.dart';
import 'package:paramedic_triage_intake/core/services/sync_service.dart';
import 'package:paramedic_triage_intake/features/triage/domain/usecases/sync_pending_usecase.dart';
import 'package:paramedic_triage_intake/features/triage/data/repositories/triage_repository_impl.dart';
import 'package:paramedic_triage_intake/features/triage/domain/entities/triage_record.dart';
import 'package:paramedic_triage_intake/core/constants/app_constants.dart';
import 'fakes.dart';

TriageRecord _sampleRecord(String id) {
  return TriageRecord(
    id: id,
    patientName: 'Test Patient',
    conditionDescription: 'Test condition',
    priority: 3,
    status: TriageStatus.pending,
    createdAt: DateTime(2026, 1, 1),
    isSynced: false,
  );
}

void main() {
  group('SyncService', () {
    test('manualSync clears pending records when the API succeeds', () async {
      final local = FakeLocalDataSource();
      final connectivity = FakeConnectivityService(isOnline: false);

      final offlineRepo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: FakeApiService(),
        connectivityService: connectivity,
      );
      await offlineRepo.saveTriage(_sampleRecord('a'));
      await offlineRepo.saveTriage(_sampleRecord('b'));

      final healthyRepo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: FakeApiService(shouldFail: (_) => false),
        connectivityService: FakeConnectivityService(isOnline: true),
      );
      final syncService = SyncService(
        syncPendingUseCase: SyncPendingUseCase(healthyRepo),
        connectivityService: FakeConnectivityService(isOnline: true),
      );

      await syncService.manualSync();

      final pending = await healthyRepo.getPending();
      expect(pending, isEmpty);
      expect(syncService.lastSyncedAt, isNotNull);

      syncService.dispose();
    });

    test('emits true then false on syncingStream while a sync runs', () async {
      final repo = TriageRepositoryImpl(
        localDataSource: FakeLocalDataSource(),
        apiService: FakeApiService(),
        connectivityService: FakeConnectivityService(isOnline: true),
      );
      final syncService = SyncService(
        syncPendingUseCase: SyncPendingUseCase(repo),
        connectivityService: FakeConnectivityService(isOnline: true),
      );

      final emittedValues = <bool>[];
      final subscription = syncService.syncingStream.listen(emittedValues.add);

      await syncService.manualSync();
      await Future<void>.delayed(Duration.zero);

      expect(emittedValues, containsAllInOrder([true, false]));

      await subscription.cancel();
      syncService.dispose();
    });

    test('does not start a second overlapping sync while one is in progress',
        () async {
      final local = FakeLocalDataSource();
      final connectivityOffline = FakeConnectivityService(isOnline: false);
      final seedRepo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: FakeApiService(),
        connectivityService: connectivityOffline,
      );
      await seedRepo.saveTriage(_sampleRecord('x'));

      final api = FakeApiService(shouldFail: (_) => false);
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: FakeConnectivityService(isOnline: true),
      );
      final syncService = SyncService(
        syncPendingUseCase: SyncPendingUseCase(repo),
        connectivityService: FakeConnectivityService(isOnline: true),
      );

      // Fire two manual syncs back-to-back without awaiting the first.
      final first = syncService.manualSync();
      final second = syncService.manualSync();
      await Future.wait([first, second]);

      // Record should only have been uploaded once despite two sync calls
      // racing, because the first covers it and the second finds nothing
      // pending (or is skipped while one is already running).
      expect(api.uploadedIds.where((id) => id == 'x').length, lessThanOrEqualTo(1));

      syncService.dispose();
    });
  });
}
