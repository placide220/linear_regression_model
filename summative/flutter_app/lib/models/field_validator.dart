import 'field_spec.dart';

/// Pure validation + coercion logic for a [FieldSpec], kept separate from
/// any widget so it's easy to reason about (and unit-test) independently
/// of the UI.
class FieldValidator {
  /// Returns an error message if [raw] is invalid for [spec], or null if valid.
  static String? validate(FieldSpec spec, String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Required';

    switch (spec.kind) {
      case FieldKind.integer:
        final parsed = int.tryParse(value);
        if (parsed == null) return 'Enter a whole number';
        if (parsed < spec.min || parsed > spec.max) {
          return 'Must be between ${spec.min} and ${spec.max}';
        }
        return null;

      case FieldKind.decimal:
        final parsed = double.tryParse(value);
        if (parsed == null) return 'Enter a decimal number';
        if (parsed < spec.min || parsed > spec.max) {
          return 'Must be between ${spec.min} and ${spec.max}';
        }
        return null;
    }
  }

  /// Converts validated raw text into the correctly-typed value
  /// (int / double) expected by the API's JSON payload.
  static dynamic coerce(FieldSpec spec, String raw) {
    final value = raw.trim();
    switch (spec.kind) {
      case FieldKind.integer:
        return int.parse(value);
      case FieldKind.decimal:
        return double.parse(value);
    }
  }
}
