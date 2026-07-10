import 'package:flutter_test/flutter_test.dart';
import 'package:paramedic_triage_intake/core/utils/validators.dart';

void main() {
  group('Validators.patientName', () {
    test('returns an error for an empty string', () {
      expect(Validators.patientName(''), isNotNull);
    });

    test('returns an error for a whitespace-only string', () {
      expect(Validators.patientName('   '), isNotNull);
    });

    test('returns null for a valid name', () {
      expect(Validators.patientName('Jane Doe'), isNull);
    });
  });

  group('Validators.conditionDescription', () {
    test('returns an error for an empty string', () {
      expect(Validators.conditionDescription(''), isNotNull);
    });

    test('returns null for a valid description', () {
      expect(Validators.conditionDescription('Chest pain, difficulty breathing'),
          isNull);
    });
  });

  group('Validators.priority', () {
    test('returns an error when priority is null', () {
      expect(Validators.priority(null), isNotNull);
    });

    test('returns an error when priority is out of range', () {
      expect(Validators.priority(0), isNotNull);
      expect(Validators.priority(6), isNotNull);
    });

    test('returns null for each valid priority 1-5', () {
      for (var p = 1; p <= 5; p++) {
        expect(Validators.priority(p), isNull);
      }
    });
  });
}
