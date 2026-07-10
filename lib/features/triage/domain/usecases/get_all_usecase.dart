import '../entities/triage_record.dart';
import '../repositories/triage_repository.dart';

/// Retrieves every triage record stored locally, most recent first, for
/// display in the submitted-records list beneath the intake form.
class GetAllUseCase {
  const GetAllUseCase(this._repository);

  final TriageRepository _repository;

  Future<List<TriageRecord>> call() => _repository.getAll();
}
