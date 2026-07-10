import '../entities/triage_record.dart';
import '../repositories/triage_repository.dart';

/// Encapsulates the single action of persisting (and opportunistically
/// uploading) a new triage record. Kept as its own use case so the
/// presentation layer never calls the repository directly - this keeps
/// business rules in one discoverable place and makes each action easy to
/// test in isolation.
class SaveTriageUseCase {
  const SaveTriageUseCase(this._repository);

  final TriageRepository _repository;

  Future<void> call(TriageRecord record) => _repository.saveTriage(record);
}
