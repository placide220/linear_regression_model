# Linear Regression Model: NSL-KDD Connection-Count Predictor

## Mission
Predict `count` — connections to the same destination host in the past two seconds — to flag scan/flood-style network anomalies early.
Dataset: NSL-KDD network intrusion detection dataset (Kaggle), repurposed for regression on this continuous target.
Problem: a regression task over 38 connection features (protocol, bytes, login/error rates, host-level stats).
Best model: Random Forest, test R² = 0.991 (vs. SGD/OLS/Decision Tree) — served via FastAPI and a Flutter app.

## Dataset
**NSL-KDD** — an improved, de-duplicated version of the classic KDD Cup 1999 network intrusion detection benchmark, one of the most widely used datasets in network-security ML research. Hosted on Kaggle (search "NSL-KDD") and other academic mirrors. Used here: `Train_data.csv` (25,192 rows) + `Test_data.csv` (22,544 rows), ~47,700 records total, with 3 categorical columns (`protocol_type`, `service` — 66 distinct values, `flag`) and 35+ numeric columns spanning byte counts, login/privilege indicators, and per-service/per-host rate statistics — genuinely rich in both volume and variety. Full EDA, correlation heatmap, and target-distribution histogram are in `summative/linear_regression/multivariate.ipynb`.

## Live API
- **Swagger UI (public):** https://api-2-56aa.onrender.com/docs
- **Predict endpoint:** `POST https://api-2-56aa.onrender.com/predict`
- Free-tier hosting: the first request after ~15 minutes of inactivity may take 30-60s to wake up.

## Video demo
- **YouTube:** _add link here_

## Repository structure
```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb      # EDA, feature engineering, 4-model comparison, training
│   ├── API/
│   │   ├── prediction.py           # FastAPI app (entry point)
│   │   ├── schemas.py              # Pydantic request/response models
│   │   ├── models/                 # saved best_model.joblib + metadata
│   │   ├── data/                   # reference training data (used by /retrain)
│   │   ├── requirements.txt        # used by Render's build (pinned, matches pyproject.toml)
│   │   ├── Dockerfile / .python-version / runtime.txt
│   │   └── README.md               # API-specific docs (CORS reasoning, endpoints, deploy steps)
│   └── FlutterApp/                 # single-page Flutter app calling the API
├── pyproject.toml                  # uv-managed dependencies (repo-wide)
├── .python-version
└── README.md                       # this file
```

## Setup (uv)
This repo uses [uv](https://docs.astral.sh/uv/) for Python package/environment management.
```bash
uv sync        # creates .venv and installs pinned dependencies from pyproject.toml
uv lock        # regenerates uv.lock if you change dependencies
```

To run the notebook:
```bash
uv run --with jupyter jupyter lab summative/linear_regression/multivariate.ipynb
```

To run the API locally:
```bash
cd summative/API
uv run uvicorn prediction:app --reload
```
Then open http://127.0.0.1:8000/docs.

## Running the Flutter app
```bash
cd summative/FlutterApp
flutter pub get
flutter run -d chrome     # or a connected device/emulator
```
The API URL is already set in `lib/config/api_config.dart` to the live Render deployment above. See `summative/FlutterApp/README.md` for full details (folder layout, field list, troubleshooting).
