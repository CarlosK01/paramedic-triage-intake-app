import 'package:paramedic_triage_intake/core/services/connectivity_service.dart';
import 'package:paramedic_triage_intake/features/triage/data/datasources/mock_api_service.dart';
import 'package:paramedic_triage_intake/features/triage/data/datasources/triage_local_datasource.dart';
import 'package:paramedic_triage_intake/features/triage/data/models/triage_record_model.dart';

/// Hand-written in-memory fake of [TriageLocalDataSource], used instead of
/// a real Hive box so repository/sync tests run fast and don't need Hive
/// initialised. Avoids pulling in a mocking framework/codegen for a small,
/// easily-faked interface.
class FakeLocalDataSource implements TriageLocalDataSource {
  final Map<String, TriageRecordModel> _store = {};

  @override
  Future<void> saveRecord(TriageRecordModel record) async {
    _store[record.id] = record;
  }

  @override
  Future<List<TriageRecordModel>> getAll() async {
    final list = _store.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<TriageRecordModel>> getPending() async {
    return _store.values.where((r) => !r.isSynced).toList();
  }

  @override
  Future<void> markSynced(String id) async {
    final record = _store[id];
    if (record != null) {
      record.isSynced = true;
    }
  }
}

/// Fake API that fails/succeeds according to a caller-supplied predicate,
/// and records every id it was asked to upload - useful for asserting
/// "continues past a failure" and "no duplicate uploads" behaviour.
class FakeApiService implements MockApiService {
  FakeApiService({bool Function(String id)? shouldFail})
      : _shouldFail = shouldFail ?? ((_) => false);

  final bool Function(String id) _shouldFail;
  final List<String> uploadedIds = [];

  @override
  Future<void> upload(TriageRecordModel record) async {
    uploadedIds.add(record.id);
    if (_shouldFail(record.id)) {
      throw Exception('Simulated failure for ${record.id}');
    }
  }
}

/// Fake connectivity that returns a fixed, caller-controlled online status,
/// with no real platform channel involved.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({required bool isOnline}) : _isOnline = isOnline;

  bool _isOnline;

  void setOnline(bool value) => _isOnline = value;

  @override
  Future<bool> isOnlineNow() async => _isOnline;

  @override
  Stream<bool> get onlineStatus => Stream.value(_isOnline);
}
