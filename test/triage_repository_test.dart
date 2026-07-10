import 'package:flutter_test/flutter_test.dart';
import 'package:paramedic_triage_intake/core/constants/app_constants.dart';
import 'package:paramedic_triage_intake/features/triage/data/repositories/triage_repository_impl.dart';
import 'package:paramedic_triage_intake/features/triage/domain/entities/triage_record.dart';
import 'fakes.dart';

TriageRecord _sampleRecord({String id = 'r1'}) {
  return TriageRecord(
    id: id,
    patientName: 'Jane Doe',
    conditionDescription: 'Severe bleeding',
    priority: 1,
    status: TriageStatus.pending,
    createdAt: DateTime(2026, 1, 1),
    isSynced: false,
  );
}

void main() {
  group('TriageRepositoryImpl.saveTriage', () {
    test('saves as synced when online and upload succeeds', () async {
      final local = FakeLocalDataSource();
      final api = FakeApiService(shouldFail: (_) => false);
      final connectivity = FakeConnectivityService(isOnline: true);
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: connectivity,
      );

      await repo.saveTriage(_sampleRecord());

      final all = await repo.getAll();
      expect(all, hasLength(1));
      expect(all.first.isSynced, isTrue);
    });

    test('saves as pending when online but upload fails', () async {
      final local = FakeLocalDataSource();
      final api = FakeApiService(shouldFail: (_) => true);
      final connectivity = FakeConnectivityService(isOnline: true);
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: connectivity,
      );

      await repo.saveTriage(_sampleRecord());

      final pending = await repo.getPending();
      expect(pending, hasLength(1));
      expect(pending.first.isSynced, isFalse);
    });

    test('saves as pending immediately when offline, without calling the API',
        () async {
      final local = FakeLocalDataSource();
      final api = FakeApiService();
      final connectivity = FakeConnectivityService(isOnline: false);
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: connectivity,
      );

      await repo.saveTriage(_sampleRecord());

      expect(api.uploadedIds, isEmpty);
      final pending = await repo.getPending();
      expect(pending, hasLength(1));
    });

    test('never throws even when the underlying upload fails', () async {
      final local = FakeLocalDataSource();
      final api = FakeApiService(shouldFail: (_) => true);
      final connectivity = FakeConnectivityService(isOnline: true);
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: connectivity,
      );

      await expectLater(repo.saveTriage(_sampleRecord()), completes);
    });
  });

  group('TriageRepositoryImpl.syncPending', () {
    test('marks a previously-pending record as synced on successful retry',
        () async {
      final local = FakeLocalDataSource();
      final connectivity = FakeConnectivityService(isOnline: false);
      final failingApi = FakeApiService(shouldFail: (_) => true);

      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: failingApi,
        connectivityService: connectivity,
      );
      // Saved while offline -> stored as pending.
      await repo.saveTriage(_sampleRecord());

      // Now simulate connectivity restored with a healthy API and re-sync.
      final healthyRepo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: FakeApiService(shouldFail: (_) => false),
        connectivityService: FakeConnectivityService(isOnline: true),
      );
      await healthyRepo.syncPending();

      final pending = await healthyRepo.getPending();
      expect(pending, isEmpty);
    });

    test('continues syncing remaining records after one fails', () async {
      final local = FakeLocalDataSource();
      final connectivity = FakeConnectivityService(isOnline: false);
      final offlineRepo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: FakeApiService(),
        connectivityService: connectivity,
      );
      await offlineRepo.saveTriage(_sampleRecord(id: 'r1'));
      await offlineRepo.saveTriage(_sampleRecord(id: 'r2'));
      await offlineRepo.saveTriage(_sampleRecord(id: 'r3'));

      // r2 fails, r1 and r3 succeed.
      final api = FakeApiService(shouldFail: (id) => id == 'r2');
      final repo = TriageRepositoryImpl(
        localDataSource: local,
        apiService: api,
        connectivityService: FakeConnectivityService(isOnline: true),
      );

      await repo.syncPending();

      final pending = await repo.getPending();
      expect(pending.map((r) => r.id), equals(['r2']));
      expect(api.uploadedIds, containsAll(['r1', 'r2', 'r3']));
    });
  });
}
