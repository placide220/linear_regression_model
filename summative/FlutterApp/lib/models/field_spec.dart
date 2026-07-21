/// Describes a single model input variable: its label, expected type, and
/// valid range/allowed values. Used to both render the correct TextFormField
/// and to validate + coerce user input before it's sent to the API.
library;

enum FieldKind { categorical, integer, decimal }

class FieldSpec {
  final String name;
  final String label;
  final FieldKind kind;
  final num? min;
  final num? max;
  final List<String>? allowedValues;

  const FieldSpec({
    required this.name,
    required this.label,
    required this.kind,
    this.min,
    this.max,
    this.allowedValues,
  });

  /// Short helper text shown under the field.
  String get hint {
    switch (kind) {
      case FieldKind.categorical:
        return allowedValues!.join(', ');
      case FieldKind.integer:
        return 'whole number, $min-$max';
      case FieldKind.decimal:
        return 'decimal, $min-$max';
    }
  }

  /// True if this is one of the small handful of fields the trained model
  /// actually relies on heavily (see [kKeyDriverFields]).
  bool get isKeyDriver => kKeyDriverFields.contains(name);
}

/// Allowed category values -- mirrors the Enum classes in the FastAPI
/// service's app/schemas.py exactly.
const List<String> kProtocolTypes = ['icmp', 'tcp', 'udp'];

const List<String> kFlags = [
  'OTH', 'REJ', 'RSTO', 'RSTOS0', 'RSTR', 'S0', 'S1', 'S2', 'S3', 'SF', 'SH'
];

const List<String> kServices = [
  'IRC', 'X11', 'Z39_50', 'auth', 'bgp', 'courier', 'csnet_ns', 'ctf',
  'daytime', 'discard', 'domain', 'domain_u', 'echo', 'eco_i', 'ecr_i',
  'efs', 'exec', 'finger', 'ftp', 'ftp_data', 'gopher', 'hostnames', 'http',
  'http_443', 'http_8001', 'imap4', 'iso_tsap', 'klogin', 'kshell', 'ldap',
  'link', 'login', 'mtp', 'name', 'netbios_dgm', 'netbios_ns',
  'netbios_ssn', 'netstat', 'nnsp', 'nntp', 'ntp_u', 'other', 'pm_dump',
  'pop_2', 'pop_3', 'printer', 'private', 'red_i', 'remote_job', 'rje',
  'shell', 'smtp', 'sql_net', 'ssh', 'sunrpc', 'supdup', 'systat', 'telnet',
  'tim_i', 'time', 'urh_i', 'urp_i', 'uucp', 'uucp_path', 'vmnet', 'whois'
];

/// The fields the trained Random Forest actually relies on most, ranked by
/// its feature_importances_ (see analysis.py / the notebook, Section 11).
/// `same_srv_rate` and `srv_count` alone account for ~90% of the model's
/// predictive weight -- everything else has only marginal influence. Used
/// to visually flag these fields in the form so it's clear at a glance
/// which inputs actually drive the prediction.
const Map<String, double> kFieldImportance = {
  'same_srv_rate': 0.523,
  'srv_count': 0.377,
  'dst_host_diff_srv_rate': 0.054,
  'diff_srv_rate': 0.023,
  'service': 0.005,
};

/// Fields highlighted in the UI as "key drivers" -- the top of
/// [kFieldImportance], everything else is negligible by comparison.
const Set<String> kKeyDriverFields = {
  'same_srv_rate',
  'srv_count',
  'dst_host_diff_srv_rate',
  'diff_srv_rate',
};
