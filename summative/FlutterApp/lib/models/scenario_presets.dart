/// One-tap test scenarios. Each only sets the handful of fields the model
/// actually relies on heavily (see [kKeyDriverFields] in field_spec.dart --
/// same_srv_rate + srv_count alone drive ~90% of every prediction). Every
/// other field is left exactly as it was (normally its pre-filled default
/// from field_defaults.dart), so testing different scenarios doesn't
/// require touching all 38 fields -- just tap a preset, then Predict.
class ScenarioPreset {
  final String label;
  final String description;
  final Map<String, String> values;

  const ScenarioPreset({
    required this.label,
    required this.description,
    required this.values,
  });
}

const List<ScenarioPreset> kScenarioPresets = [
  ScenarioPreset(
    label: 'Typical traffic',
    description: 'One session, concentrated on a single service -- low expected count.',
    values: {
      'srv_count': '5',
      'same_srv_rate': '1.0',
      'dst_host_diff_srv_rate': '0.0',
      'diff_srv_rate': '0.0',
    },
  ),
  ScenarioPreset(
    label: 'Moderate load',
    description: 'Traffic spread across a mix of services -- medium expected count.',
    values: {
      'srv_count': '50',
      'same_srv_rate': '0.5',
      'dst_host_diff_srv_rate': '0.2',
      'diff_srv_rate': '0.2',
    },
  ),
  ScenarioPreset(
    label: 'Scan-like / suspicious',
    description: 'Many connections spread thin across services -- classic scan/flood pattern.',
    values: {
      'srv_count': '300',
      'same_srv_rate': '0.05',
      'dst_host_diff_srv_rate': '0.8',
      'diff_srv_rate': '0.7',
    },
  ),
];
