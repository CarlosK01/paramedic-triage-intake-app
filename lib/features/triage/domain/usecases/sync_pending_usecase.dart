import '../repositories/triage_repository.dart';

/// Triggers an upload attempt for every currently pending record. Used by
/// [SyncService] both on connectivity-restored events and on app-resume
/// lifecycle events.
class SyncPendingUseCase {
  const SyncPendingUseCase(this._repository);

  final TriageRepository _repository;

  Future<void> call() => _repository.syncPending();
}
