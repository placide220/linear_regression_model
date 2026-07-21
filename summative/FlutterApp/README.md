# Connection Count Predictor — Flutter App (Task 3)

A single-page Flutter app that calls the FastAPI `/predict` endpoint from
Task 2 and displays the predicted `count` value.

## What's in this folder
```
flutter_app/
├── lib/
│   ├── main.dart                          # app entry point (MaterialApp only)
│   ├── config/
│   │   └── api_config.dart                # API base URL + path constants
│   ├── models/
│   │   ├── field_spec.dart                # FieldSpec class, FieldKind enum, category value lists
│   │   ├── field_sections.dart            # the 38 fields, grouped into labeled sections
│   │   └── field_validator.dart           # validation + type-coercion logic (pure, no UI)
│   ├── services/
│   │   └── prediction_service.dart        # all networking: calls POST /predict, parses errors
│   ├── widgets/
│   │   ├── prediction_field.dart          # one TextFormField per model variable
│   │   ├── section_card.dart              # labeled card grouping related fields
│   │   └── result_banner.dart             # idle/loading/success/error display area
│   └── pages/
│       └── prediction_page.dart           # the single page, wires everything together
├── pubspec.yaml
└── README.md
```
Each concern lives in its own file: field definitions, validation, networking,
and each UI piece are all separated rather than crammed into `main.dart`.
This is still a **single-page app** — the file split is purely internal
code organization, not multiple screens/routes.

> **Disclosure:** this sandbox has no Flutter SDK and no internet access,
> so I was not able to run `flutter create`, `flutter pub get`, or
> `flutter run`/`flutter analyze` to compile-check this. I traced through
> the code by hand and cross-checked every field name against the FastAPI
> Pydantic schema (`api/app/schemas.py`) to confirm all 38 variables match
> exactly, but please run `flutter analyze` yourself after setup, before
> you rely on it, in case anything needs a small fix for your Flutter/Dart
> SDK version.

## Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) if you haven't already.
2. Create a fresh Flutter project skeleton, then drop these files in:
   ```bash
   flutter create count_predictor_app
   cd count_predictor_app
   # replace the generated lib/ folder and pubspec.yaml with the ones from this project
   rm -rf lib
   cp -r /path/to/flutter_app/lib lib
   cp /path/to/flutter_app/pubspec.yaml pubspec.yaml
   flutter pub get
   ```
3. **API URL is already set** — `kApiBaseUrl` in `lib/main.dart` is already pointed at your deployed service:
   ```dart
   const String kApiBaseUrl = "https://api-2-56aa.onrender.com";
   ```
   If you redeploy to a different Render URL later, update this constant.
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

## What the app does

- **One page** (`PredictionPage`), no navigation.
- **38 `TextFormField`s** — exactly one per model input variable (3
  categorical: `protocol_type`, `service`, `flag`; 35 numeric), grouped
  under labeled section cards (Connection type, Traffic volume, Connection
  flags, etc.) purely for readability — it's still a single scrollable page.
- Each field shows its valid range/allowed values as helper text, and is
  validated **client-side** (required + type + range) using the same
  bounds as the Pydantic model in Task 2, so obviously-bad input is caught
  before a network call is even made.
- **"Predict" button** — disabled while a request is in flight (shows a
  spinner instead).
- **Display area** at the bottom that shows:
  - the predicted value on success (green),
  - a clear error message for validation failures, missing fields, or a
    422 response from the server (red),
  - a generic connection-error message if the API can't be reached (red).

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
