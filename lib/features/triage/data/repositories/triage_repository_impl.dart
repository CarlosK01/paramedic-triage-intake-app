import 'dart:developer' as developer;
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/triage_record.dart';
import '../../domain/repositories/triage_repository.dart';
import '../datasources/mock_api_service.dart';
import '../datasources/triage_local_datasource.dart';
import '../models/triage_record_model.dart';

/// Concrete implementation of [TriageRepository]: the only place in the app
/// that knows about both Hive persistence and the mock network API, and
/// therefore the only place that implements the offline-first decision
/// logic described in the assessment brief.
class TriageRepositoryImpl implements TriageRepository {
  TriageRepositoryImpl({
    required TriageLocalDataSource localDataSource,
    required MockApiService apiService,
    required ConnectivityService connectivityService,
  })  : _localDataSource = localDataSource,
        _apiService = apiService,
        _connectivityService = connectivityService;

  final TriageLocalDataSource _localDataSource;
  final MockApiService _apiService;
  final ConnectivityService _connectivityService;

  @override
  Future<void> saveTriage(TriageRecord record) async {
    final model = TriageRecordModel.fromEntity(record);

    // Always persist locally first and immediately - the record must never
    // be lost, regardless of what happens next with the network.
    final isOnline = await _connectivityService.isOnlineNow();

    if (isOnline) {
      try {
        await _apiService.upload(model);
        model.isSynced = true;
      } catch (e) {
        // Upload failed even though we appeared online (e.g. simulated
        // 30% failure, or a flaky connection) - fall back to pending.
        model.isSynced = false;
        developer.log('Initial upload failed, saved as pending: $e',
            name: 'TriageRepository');
      }
    } else {
      // No connectivity at all - save immediately as pending, no attempt.
      model.isSynced = false;
    }

    await _localDataSource.saveRecord(model);
  }

  @override
  Future<List<TriageRecord>> getPending() async {
    final models = await _localDataSource.getPending();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TriageRecord>> getAll() async {
    final models = await _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> syncPending() async {
    final pending = await _localDataSource.getPending();

    // Sequential, not parallel: keeps upload order predictable and avoids
    // hammering the (simulated) backend with a burst of concurrent calls.
    for (final model in pending) {
      try {
        await _apiService.upload(model);
        await _localDataSource.markSynced(model.id);
      } catch (e) {
        // Log and continue - one failing record must never block the rest
        // of the queue from syncing.
        developer.log('Sync failed for record ${model.id}: $e',
            name: 'TriageRepository');
      }
    }
  }
}
