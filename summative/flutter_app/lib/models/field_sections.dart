import 'field_spec.dart';

/// The 4 model input variables. All 4 are shown in a single section since
/// there's no longer a meaningful grouping to make with so few fields --
/// every one of them is a genuine "key driver" of the prediction.
final Map<String, List<FieldSpec>> kSections = {
  'Connection features': [
    const FieldSpec(
      name: 'same_srv_rate',
      label: 'Same srv rate',
      kind: FieldKind.decimal,
      min: 0,
      max: 1,
      importanceNote: '~52% of model weight (most important feature)',
    ),
    const FieldSpec(
      name: 'srv_count',
      label: 'Srv count',
      kind: FieldKind.integer,
      min: 1,
      max: 511,
      importanceNote: '~38% of model weight',
    ),
    const FieldSpec(
      name: 'dst_host_diff_srv_rate',
      label: 'Dst host diff srv rate',
      kind: FieldKind.decimal,
      min: 0,
      max: 1,
      importanceNote: '~5% of model weight',
    ),
    const FieldSpec(
      name: 'diff_srv_rate',
      label: 'Diff srv rate',
      kind: FieldKind.decimal,
      min: 0,
      max: 1,
      importanceNote: '~2% of model weight',
    ),
  ],
};

/// Flattened list of every field across all sections, in display order.
List<FieldSpec> get kAllFields => kSections.values.expand((f) => f).toList();
