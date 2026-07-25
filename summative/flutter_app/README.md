# Connection Count Predictor — Flutter App (Task 3)

A single-page Flutter app that calls the FastAPI `/predict` endpoint from
Task 2 and displays the predicted `count` value.

## Design
Styled as a dark "network operations console" rather than default Material
blue-on-white, since the subject (network intrusion detection) calls for
something closer to a technical monitoring dashboard: deep navy surfaces,
a single cyan signal color, a geometric display face (Space Grotesk) for
headers, and a monospace face (JetBrains Mono) for data entry and the
predicted-value readout. All tokens live in `lib/theme/app_theme.dart`.

Fields the model relies on most (`same_srv_rate`, `srv_count`,
`dst_host_diff_srv_rate`, `diff_srv_rate` — see the notebook's feature
importance analysis) are marked with a small cyan dot indicator, and 3
one-tap "quick test scenario" chips fill in representative values for
those fields without needing to type anything.

## What's in this folder
```
FlutterApp/
├── lib/
│   ├── main.dart                          # app entry point (MaterialApp + theme)
│   ├── theme/
│   │   └── app_theme.dart                 # color tokens, typography, component themes
│   ├── config/
│   │   └── api_config.dart                # API base URL + path constants
│   ├── models/
│   │   ├── field_spec.dart                # FieldSpec class, FieldKind enum, category value lists
│   │   ├── field_sections.dart            # the 38 fields, grouped into labeled sections
│   │   ├── field_defaults.dart            # pre-filled example values
│   │   ├── field_validator.dart           # validation + type-coercion logic (pure, no UI)
│   │   └── scenario_presets.dart          # one-tap test scenarios (typical / moderate / suspicious)
│   ├── services/
│   │   └── prediction_service.dart        # all networking: calls POST /predict, parses errors
│   ├── widgets/
│   │   ├── prediction_field.dart          # one TextFormField per model variable
│   │   ├── section_card.dart              # labeled panel grouping related fields, with icon
│   │   └── result_banner.dart             # idle/loading/success/error display area
│   └── pages/
│       └── prediction_page.dart           # the single page, wires everything together
├── pubspec.yaml
└── README.md
```
Each concern lives in its own file: field definitions, validation, networking,
theming, and each UI piece are all separated rather than crammed into
`main.dart`. This is still a **single-page app** — the file split is purely
internal code organization, not multiple screens/routes.

## Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) if you haven't already.
2. Create a fresh Flutter project skeleton, then drop these files in:
   ```bash
   flutter create count_predictor_app
   cd count_predictor_app
   # replace the generated lib/ folder and pubspec.yaml with the ones from this project
   rm -rf lib
   cp -r /path/to/FlutterApp/lib lib
   cp /path/to/FlutterApp/pubspec.yaml pubspec.yaml
   flutter pub get
   ```
   `flutter pub get` will also fetch `google_fonts`, used for the app's typography.
3. **API URL is already set** in `lib/config/api_config.dart`:
   ```dart
   const String kApiBaseUrl = "https://api-2-56aa.onrender.com";
   ```
   Update this constant if you redeploy to a different Render URL.
4. Run it:
   ```bash
   flutter run -d chrome     # easiest for quick testing
   # or
   flutter run                # on a connected device/emulator
   ```

### Android emulator note
If you test against a FastAPI server running on `localhost` on your own
machine (rather than the deployed Render URL), the Android emulator can't
reach `localhost` directly — use `http://10.0.2.2:8000` instead. This
doesn't apply once you point `kApiBaseUrl` at the deployed Render URL.

### Render cold starts
The deployed API is on Render's free tier, which sleeps after ~15 minutes
idle. The first request after that can take 30-60 seconds to respond — the
app's request timeout is set to 60s to tolerate this. Hit
`https://api-2-56aa.onrender.com/health` in a browser first to warm the
server up before demoing.

## What the app does

- **One page** (`PredictionPage`), no navigation.
- **38 `TextFormField`s** — exactly one per model input variable (3
  categorical: `protocol_type`, `service`, `flag`; 35 numeric), grouped
  under labeled panel cards (Connection type, Traffic volume, Connection
  flags, etc.), each with an icon hinting at what it measures.
- Each field shows its valid range/allowed values as helper text, and is
  validated **client-side** (required + type + range) using the same
  bounds as the Pydantic model in Task 2.
- **Key-driver indicator** — a small cyan dot on the 4 fields the model
  relies on most (see `field_spec.dart`'s `isKeyDriver`).
- **Quick test scenario chips** (Typical traffic / Moderate load /
  Scan-like suspicious) that fill in representative values for those 4
  key-driver fields in one tap.
- **"Predict" button** — disabled while a request is in flight (shows a
  spinner instead).
- **Display area** at the bottom: on success, a large monospace readout of
  the predicted value (green accent); on validation failure, missing
  fields, or a 422 from the server, a clear red error message; on a
  connection problem, a distinct red message explaining that.

## Field list (matches Task 2's `PredictionInput` schema exactly)
protocol_type, service, flag, duration, src_bytes, dst_bytes, land,
wrong_fragment, urgent, hot, num_failed_logins, logged_in, num_compromised,
root_shell, su_attempted, num_root, num_file_creations, num_shells,
num_access_files, is_guest_login, srv_count, dst_host_count,
dst_host_srv_count, serror_rate, srv_serror_rate, rerror_rate,
srv_rerror_rate, same_srv_rate, diff_srv_rate, srv_diff_host_rate,
dst_host_same_srv_rate, dst_host_diff_srv_rate,
dst_host_same_src_port_rate, dst_host_srv_diff_host_rate,
dst_host_serror_rate, dst_host_srv_serror_rate, dst_host_rerror_rate,
dst_host_srv_rerror_rate
