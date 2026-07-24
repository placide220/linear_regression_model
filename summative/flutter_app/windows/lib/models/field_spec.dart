/// Describes a single model input variable: its label, expected type, and
/// valid range. Used to both render the correct TextFormField and to
/// validate + coerce user input before it's sent to the API.
///
/// The API was simplified from an initial 38-feature version down to just
/// the 4 fields below (see schemas.py / the notebook, Section 11): these
/// 4 numeric features alone reach ~98.3% test R^2, within 0.8 points of
/// the full 38-feature model's 0.991 -- so all 34 other near-zero-
/// importance features (including every categorical column) were dropped
/// entirely, both from the deployed model and from this form.
library;

enum FieldKind { integer, decimal }

class FieldSpec {
  final String name;
  final String label;
  final FieldKind kind;
  final num min;
  final num max;
  final String importanceNote;

  const FieldSpec({
    required this.name,
    required this.label,
    required this.kind,
    required this.min,
    required this.max,
    required this.importanceNote,
  });

  /// Short helper text shown under the field.
  String get hint {
    final range = kind == FieldKind.integer
        ? 'whole number, $min-$max'
        : 'decimal, $min-$max';
    return '$range -- $importanceNote';
  }
}
