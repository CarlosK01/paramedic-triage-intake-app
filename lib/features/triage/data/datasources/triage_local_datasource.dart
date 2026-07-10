import 'package:hive/hive.dart';
import '../models/triage_record_model.dart';

/// Local persistence contract, isolated from the repository so the
/// repository can be tested against a fake datasource without touching a
/// real Hive box.
abstract class TriageLocalDataSource {
  Future<void> saveRecord(TriageRecordModel record);
  Future<List<TriageRecordModel>> getAll();
  Future<List<TriageRecordModel>> getPending();
  Future<void> markSynced(String id);
}

/// Hive-backed implementation. Records are keyed by their own [id], so
/// `saveRecord` naturally acts as an upsert - re-saving a record with the
/// same id (e.g. after a successful sync) simply overwrites it in place.
class TriageLocalDataSourceImpl implements TriageLocalDataSource {
  TriageLocalDataSourceImpl(this._box);

  final Box<TriageRecordModel> _box;

  @override
  Future<void> saveRecord(TriageRecordModel record) async {
    await _box.put(record.id, record);
  }

  @override
  Future<List<TriageRecordModel>> getAll() async {
    final records = _box.values.toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  @override
  Future<List<TriageRecordModel>> getPending() async {
    return _box.values.where((record) => !record.isSynced).toList();
  }

  @override
  Future<void> markSynced(String id) async {
    final record = _box.get(id);
    if (record == null) return;
    record.isSynced = true;
    await record.save();
  }
}
