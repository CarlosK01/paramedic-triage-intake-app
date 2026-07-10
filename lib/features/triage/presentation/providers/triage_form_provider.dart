import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/triage_record.dart';
import 'triage_providers.dart';

/// Immutable snapshot of the intake form's current state, including
/// per-field validation error messages (null when a field is valid or has
/// not been validated yet).
class TriageFormState {
  const TriageFormState({
    this.patientName = '',
    this.conditionDescription = '',
    this.priority,
    this.status = TriageStatus.pending,
    this.isSubmitting = false,
    this.patientNameError,
    this.conditionError,
    this.priorityError,
  });

  final String patientName;
  final String conditionDescription;
  final int? priority;
  final TriageStatus status;
  final bool isSubmitting;
  final String? patientNameError;
  final String? conditionError;
  final String? priorityError;

  bool get hasErrors =>
      patientNameError != null || conditionError != null || priorityError != null;

  TriageFormState copyWith({
    String? patientName,
    String? conditionDescription,
    int? priority,
    TriageStatus? status,
    bool? isSubmitting,
    String? patientNameError,
    String? conditionError,
    String? priorityError,
    bool clearPatientNameError = false,
    bool clearConditionError = false,
    bool clearPriorityError = false,
  }) {
    return TriageFormState(
      patientName: patientName ?? this.patientName,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      patientNameError:
          clearPatientNameError ? null : (patientNameError ?? this.patientNameError),
      conditionError:
          clearConditionError ? null : (conditionError ?? this.conditionError),
      priorityError:
          clearPriorityError ? null : (priorityError ?? this.priorityError),
    );
  }
}

/// Owns the intake form's state and validation/submit workflow. The
/// widgets are entirely dumb wrt business logic - they read this state and
/// call [updatePatientName] / [submit] etc.
class TriageFormNotifier extends StateNotifier<TriageFormState> {
  TriageFormNotifier(this._ref) : super(const TriageFormState());

  final Ref _ref;
  static const _uuid = Uuid();

  void updatePatientName(String value) {
    state = state.copyWith(patientName: value, clearPatientNameError: true);
  }

  void updateConditionDescription(String value) {
    state = state.copyWith(conditionDescription: value, clearConditionError: true);
  }

  void updatePriority(int value) {
    state = state.copyWith(priority: value, clearPriorityError: true);
  }

  void updateStatus(TriageStatus value) {
    state = state.copyWith(status: value);
  }

  bool _validate() {
    final nameError = Validators.patientName(state.patientName);
    final conditionError = Validators.conditionDescription(state.conditionDescription);
    final priorityError = Validators.priority(state.priority);

    state = state.copyWith(
      patientNameError: nameError,
      conditionError: conditionError,
      priorityError: priorityError,
      clearPatientNameError: nameError == null,
      clearConditionError: conditionError == null,
      clearPriorityError: priorityError == null,
    );

    return nameError == null && conditionError == null && priorityError == null;
  }

  /// Validates, and if valid, builds a [TriageRecord] and hands it to
  /// [SaveTriageUseCase] via [saveTriageUseCaseProvider]. Returns `true` on a
  /// successful submit (so the UI knows whether to show the success
  /// snackbar), `false` if validation failed.
  Future<bool> submit() async {
    if (!_validate()) return false;

    state = state.copyWith(isSubmitting: true);
    try {
      final record = TriageRecord(
        id: _uuid.v4(),
        patientName: state.patientName.trim(),
        conditionDescription: state.conditionDescription.trim(),
        priority: state.priority!,
        status: state.status,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      await _ref.read(saveTriageUseCaseProvider).call(record);
      _ref.invalidate(allRecordsProvider);
      reset();
      return true;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  void reset() {
    state = const TriageFormState();
  }
}

final triageFormProvider =
    StateNotifierProvider<TriageFormNotifier, TriageFormState>((ref) {
  return TriageFormNotifier(ref);
});
