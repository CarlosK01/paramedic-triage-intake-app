import '../entities/triage_record.dart';

/// Contract for triage data access. The domain and presentation layers
/// depend only on this abstraction, never on the concrete Hive/mock-API
/// implementation - this is what lets us swap persistence or backend
/// strategy later (or substitute fakes in tests) without touching UI code.
abstract class TriageRepository {
  /// Persists [record] locally immediately, and attempts an upload if the
  /// device currently has connectivity. Never throws on upload failure -
  /// that failure is captured as `isSynced = false` on the stored record.
  Future<void> saveTriage(TriageRecord record);

  /// Returns all records that have not yet been successfully synced.
  Future<List<TriageRecord>> getPending();

  /// Returns every record stored locally, most recent first.
  Future<List<TriageRecord>> getAll();

  /// Attempts to upload every pending record. Continues past individual
  /// failures so one bad record never blocks the rest of the queue.
  Future<void> syncPending();
}
