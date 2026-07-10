import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:paramedic_triage_intake/core/constants/app_constants.dart';
import 'package:paramedic_triage_intake/features/triage/data/datasources/mock_api_service.dart';
import 'package:paramedic_triage_intake/features/triage/data/models/triage_record_model.dart';

TriageRecordModel _sampleRecord() {
  return TriageRecordModel(
    id: 'test-id-1',
    patientName: 'John Doe',
    conditionDescription: 'Fracture, left arm',
    priority: 2,
    statusIndex: TriageStatus.pending.index,
    createdAt: DateTime(2026, 1, 1),
    isSynced: false,
  );
}

void main() {
  group('MockApiService', () {
    test('always succeeds when random is seeded to never hit the failure band',
        () async {
      // Random(1) with nextDouble() >= 0.3 guaranteed is awkward to force
      // deterministically without controlling the seed's exact sequence,
      // so instead we use a fake Random that always returns a high value.
      final service = MockApiService(random: _FixedRandom(0.99));
      await expectLater(service.upload(_sampleRecord()), completes);
    });

    test('always throws when random is fixed inside the failure band',
        () async {
      final service = MockApiService(random: _FixedRandom(0.01));
      expect(
        () => service.upload(_sampleRecord()),
        throwsA(isA<Exception>()),
      );
    });

    test('introduces the configured artificial delay', () async {
      final service = MockApiService(random: _FixedRandom(0.99));
      final stopwatch = Stopwatch()..start();
      await service.upload(_sampleRecord());
      stopwatch.stop();
      expect(
        stopwatch.elapsed >= AppConstants.mockApiDelay,
        isTrue,
        reason: 'upload() should wait at least the configured mock delay',
      );
    });
  });
}

/// A [Random] stand-in that always returns the same value from
/// `nextDouble()`, letting tests deterministically force success or
/// failure instead of relying on statistical repetition.
class _FixedRandom implements Random {
  _FixedRandom(this._value);
  final double _value;

  @override
  double nextDouble() => _value;

  @override
  int nextInt(int max) => (_value * max).floor();

  @override
  bool nextBool() => _value >= 0.5;

  @override
  int nextRawSeed() => 0;
}
