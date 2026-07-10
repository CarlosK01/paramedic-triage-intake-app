import '../entities/triage_record.dart';
import '../repositories/triage_repository.dart';

/// Retrieves all triage records that have not yet been successfully synced
/// to the backend.
class GetPendingUseCase {
  const GetPendingUseCase(this._repository);

  final TriageRepository _repository;

  Future<List<TriageRecord>> call() => _repository.getPending();
}
