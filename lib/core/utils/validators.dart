/// Pure, side-effect-free validation functions for the triage intake form.
/// Kept separate from widgets and state so they can be unit tested in
/// isolation and reused anywhere form-level validation is needed.
class Validators {
  Validators._();

  static String? patientName(String value) {
    if (value.trim().isEmpty) {
      return 'Patient name is required';
    }
    return null;
  }

  static String? conditionDescription(String value) {
    if (value.trim().isEmpty) {
      return 'Condition description is required';
    }
    return null;
  }

  static String? priority(int? value) {
    if (value == null) {
      return 'Priority level is required';
    }
    if (value < 1 || value > 5) {
      return 'Priority must be between 1 and 5';
    }
    return null;
  }
}
