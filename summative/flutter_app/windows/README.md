# Connection Count Predictor — Flutter App (Task 3)

A single-page Flutter app that calls the FastAPI `/predict` endpoint from
Task 2 and displays the predicted `count` value.

## Why only 4 fields
This app originally had 38 input fields, matching the full feature set the
model was first trained on. Random Forest's feature-importance analysis
(see the notebook, Section 11) showed that just 4 of those 38 features --
`same_srv_rate`, `srv_count`, `dst_host_diff_srv_rate`, `diff_srv_rate` --
account for essentially all of the model's predictive power. Retraining on
just those 4 reaches 0.983 test R^2, within 0.8 points of the full
38-feature model's 0.991. The deployed API and this app were both
simplified to use only these 4 fields, since the other 34 contributed
almost nothing but made the form far more tedious to fill in and test.

## What's in this folder
```
FlutterApp/
├── lib/
│   ├── main.dart                          # app entry point (MaterialApp only)
│   ├── config/
│   │   └── api_config.dart                # API base URL + path constants
│   ├── models/
│   │   ├── field_spec.dart                # FieldSpec class, FieldKind enum
│   │   ├── field_sections.dart            # the 4 fields
│   │   ├── field_defaults.dart            # pre-filled example values
│   │   ├── field_validator.dart           # validation + type-coercion logic (pure, no UI)
│   │   └── scenario_presets.dart          # one-tap test scenarios (typical / moderate / suspicious)
│   ├── services/
│   │   └── prediction_service.dart        # all networking: calls POST /predict, parses errors
│   ├── widgets/
│   │   ├── prediction_field.dart          # one TextFormField per model variable
│   │   ├── section_card.dart              # labeled card grouping fields
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

## What the app does

- **One page** (`PredictionPage`), no navigation.
- **4 `TextFormField`s** — exactly one per model input variable, all
  grouped in a single "Connection features" card (there's no longer a
  meaningful subgrouping to make with only 4 fields).
- Each field shows its valid range and its share of the model's predictive
  weight as helper text, and is validated **client-side** (required + type
  + range) using the same bounds as the Pydantic model in Task 2.
- **Quick test scenario chips** (Typical traffic / Moderate load /
  Scan-like suspicious) that fill in representative values in one tap.
- **"Predict" button** — disabled while a request is in flight (shows a
  spinner instead).
- **Display area** at the bottom that shows:
  - the predicted value on success (green),
  - a clear error message for validation failures, missing fields, or a
    422 response from the server (red),
  - a generic connection-error message if the API can't be reached (red).

## Field list (matches Task 2's `PredictionInput` schema exactly)
| Field | Range | Model weight |
|---|---|---|
| `same_srv_rate` | 0.0 - 1.0 | ~52% |
| `srv_count` | 1 - 511 | ~38% |
| `dst_host_diff_srv_rate` | 0.0 - 1.0 | ~5% |
| `diff_srv_rate` | 0.0 - 1.0 | ~2% |
