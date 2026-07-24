import 'field_spec.dart';

/// All 38 model input variables, grouped into sections purely for visual
/// organization -- every field still renders as its own individual
/// TextFormField (one per model variable, per the assignment requirement);
/// the grouping just keeps a 38-field form readable instead of one long
/// unbroken list.
final Map<String, List<FieldSpec>> kSections = {
  'Connection type': [
    const FieldSpec(name: 'protocol_type', label: 'Protocol type', kind: FieldKind.categorical, allowedValues: kProtocolTypes),
    const FieldSpec(name: 'service', label: 'Service', kind: FieldKind.categorical, allowedValues: kServices),
    const FieldSpec(name: 'flag', label: 'Flag', kind: FieldKind.categorical, allowedValues: kFlags),
  ],
  'Traffic volume': [
    const FieldSpec(name: 'duration', label: 'Duration (seconds)', kind: FieldKind.integer, min: 0, max: 42862),
    const FieldSpec(name: 'src_bytes', label: 'Source bytes', kind: FieldKind.integer, min: 0, max: 381709090),
    const FieldSpec(name: 'dst_bytes', label: 'Destination bytes', kind: FieldKind.integer, min: 0, max: 5151385),
  ],
  'Connection flags': [
    const FieldSpec(name: 'land', label: 'Land (0 or 1)', kind: FieldKind.integer, min: 0, max: 1),
    const FieldSpec(name: 'wrong_fragment', label: 'Wrong fragment', kind: FieldKind.integer, min: 0, max: 3),
    const FieldSpec(name: 'urgent', label: 'Urgent packets', kind: FieldKind.integer, min: 0, max: 1),
    const FieldSpec(name: 'hot', label: 'Hot indicators', kind: FieldKind.integer, min: 0, max: 77),
    const FieldSpec(name: 'num_failed_logins', label: 'Failed logins', kind: FieldKind.integer, min: 0, max: 4),
    const FieldSpec(name: 'logged_in', label: 'Logged in (0 or 1)', kind: FieldKind.integer, min: 0, max: 1),
  ],
  'Compromise indicators': [
    const FieldSpec(name: 'num_compromised', label: 'Num compromised', kind: FieldKind.integer, min: 0, max: 884),
    const FieldSpec(name: 'root_shell', label: 'Root shell (0 or 1)', kind: FieldKind.integer, min: 0, max: 1),
    const FieldSpec(name: 'su_attempted', label: 'Su attempted', kind: FieldKind.integer, min: 0, max: 2),
    const FieldSpec(name: 'num_root', label: 'Num root', kind: FieldKind.integer, min: 0, max: 975),
    const FieldSpec(name: 'num_file_creations', label: 'File creations', kind: FieldKind.integer, min: 0, max: 40),
    const FieldSpec(name: 'num_shells', label: 'Num shells', kind: FieldKind.integer, min: 0, max: 1),
    const FieldSpec(name: 'num_access_files', label: 'Num access files', kind: FieldKind.integer, min: 0, max: 8),
    const FieldSpec(name: 'is_guest_login', label: 'Guest login (0 or 1)', kind: FieldKind.integer, min: 0, max: 1),
  ],
  'Same-window counts': [
    const FieldSpec(name: 'srv_count', label: 'Srv count', kind: FieldKind.integer, min: 1, max: 511),
    const FieldSpec(name: 'dst_host_count', label: 'Dst host count', kind: FieldKind.integer, min: 0, max: 255),
    const FieldSpec(name: 'dst_host_srv_count', label: 'Dst host srv count', kind: FieldKind.integer, min: 0, max: 255),
  ],
  'Rate features (0.0 - 1.0)': [
    const FieldSpec(name: 'serror_rate', label: 'Serror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'srv_serror_rate', label: 'Srv serror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'rerror_rate', label: 'Rerror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'srv_rerror_rate', label: 'Srv rerror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'same_srv_rate', label: 'Same srv rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'diff_srv_rate', label: 'Diff srv rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'srv_diff_host_rate', label: 'Srv diff host rate', kind: FieldKind.decimal, min: 0, max: 1),
  ],
  'Destination-host rate features (0.0 - 1.0)': [
    const FieldSpec(name: 'dst_host_same_srv_rate', label: 'Dst host same srv rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_diff_srv_rate', label: 'Dst host diff srv rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_same_src_port_rate', label: 'Dst host same src port rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_srv_diff_host_rate', label: 'Dst host srv diff host rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_serror_rate', label: 'Dst host serror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_srv_serror_rate', label: 'Dst host srv serror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_rerror_rate', label: 'Dst host rerror rate', kind: FieldKind.decimal, min: 0, max: 1),
    const FieldSpec(name: 'dst_host_srv_rerror_rate', label: 'Dst host srv rerror rate', kind: FieldKind.decimal, min: 0, max: 1),
  ],
};

/// Flattened list of every field across all sections, in display order.
List<FieldSpec> get kAllFields => kSections.values.expand((f) => f).toList();
