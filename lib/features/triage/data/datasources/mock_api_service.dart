import 'dart:math';
import '../models/triage_record_model.dart';
import '../../../../core/constants/app_constants.dart';

/// Simulated backend endpoint (`POST /api/v1/triage`), since the assessment
/// is mobile-only and does not require a real server.
///
/// Introduces a realistic artificial delay and a random failure rate so the
/// offline-first / retry logic can be exercised and demonstrated without
/// needing an actual flaky network.
class MockApiService {
  MockApiService({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Simulates uploading [record] to the backend. Completes normally on
  /// success; throws an [Exception] on simulated failure so callers can
  /// treat this exactly like a real failed HTTP request.
  Future<void> upload(TriageRecordModel record) async {
    await Future.delayed(AppConstants.mockApiDelay);
    if (_random.nextDouble() < AppConstants.mockApiFailureRate) {
      throw Exception(
        'Simulated network failure while uploading record ${record.id}',
      );
    }
  }
}
