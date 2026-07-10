/// App-wide constants: box names, simulated network behaviour, and enums
/// shared across layers.
class AppConstants {
  AppConstants._();

  /// Name of the Hive box used to persist triage records locally.
  static const String triageBoxName = 'triage_records_box';

  /// Artificial network delay used by [MockApiService] to simulate a
  /// realistic upload round-trip.
  static const Duration mockApiDelay = Duration(seconds: 2);

  /// Probability (0.0 - 1.0) that a simulated upload fails, used to exercise
  /// the offline/retry logic during development and testing.
  static const double mockApiFailureRate = 0.3;
}

/// Status of a triage record as chosen by the paramedic on the intake form.
/// This is independent from [isSynced], which tracks whether the record has
/// reached the backend.
enum TriageStatus {
  pending,
  inTransit;

  String get label {
    switch (this) {
      case TriageStatus.pending:
        return 'Pending';
      case TriageStatus.inTransit:
        return 'In-Transit';
    }
  }
}
