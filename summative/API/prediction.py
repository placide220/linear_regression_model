"""
FastAPI service for the NSL-KDD `count` regression model.

Endpoints
---------
GET  /                  -> redirects to the Swagger UI (/docs)
GET  /health            -> liveness/model-loaded check
POST /predict           -> single-record prediction
POST /predict/batch     -> multi-record prediction (list of records)
POST /retrain           -> upload a CSV of new labeled data, retrain immediately
POST /data/ingest       -> upload a CSV of new labeled data WITHOUT retraining now;
                            it's queued and picked up automatically by a background
                            watcher, which is the "reactive to new data" path
GET  /retrain/status    -> info about the last automatic retrain

Run locally:
    uvicorn prediction:app --reload

Swagger UI:  http://127.0.0.1:8000/docs
ReDoc:       http://127.0.0.1:8000/redoc
"""
import asyncio
import io
import os
import shutil
import time
from typing import List

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from schemas import (
    HealthResponse,
    IngestResponse,
    PredictionInput,
    PredictionOutput,
    RetrainResponse,
    RetrainStatusResponse,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "models", "best_model.joblib")
META_PATH = os.path.join(BASE_DIR, "models", "model_metadata.joblib")
REFERENCE_DATA_PATH = os.path.join(BASE_DIR, "data", "reference_train_data.csv")
INCOMING_DIR = os.path.join(BASE_DIR, "data", "incoming")
PROCESSED_DIR = os.path.join(BASE_DIR, "data", "processed")
POLL_INTERVAL_SECONDS = int(os.environ.get("RETRAIN_POLL_SECONDS", "30"))

app = FastAPI(
    title="NSL-KDD Connection Count Regressor API",
    description=(
        "Predicts `count` (connections to the same destination host in the "
        "past 2 seconds) from network connection features, using the best "
        "of four regression models (SGD / OLS / Random Forest / Decision "
        "Tree) selected during training. Includes both an on-demand and an "
        "automatic, background retraining path -- see /retrain and "
        "/data/ingest."
    ),
    version="1.1.0",
)

# ---------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------
# Reasoning (deliberately NOT a wildcard "*" on any setting):
# - allow_origins: an explicit allowlist, not "*". This API is meant to be
#   called from (a) the Swagger UI, which is served from this same origin
#   so it needs no CORS entry at all, and (b) a specific web frontend --
#   here, a Flutter *web* build if one is deployed. Only those concrete
#   origins are listed. Note the Flutter *mobile* app (Task 3) is not a
#   browser, so CORS does not apply to it at all -- CORS only restricts
#   browser-based JS clients, never native/mobile HTTP clients. The list is
#   still overridable via the ALLOWED_ORIGINS env var (comma-separated) so
#   the same image can be locked to a different real frontend domain per
#   deployment without touching code.
# - allow_credentials=False: this API uses no cookies or server-side
#   sessions (predictions are stateless), so there is nothing to send
#   credentials for, and it keeps the origin allowlist meaningfully
#   restrictive rather than a formality.
# - allow_methods: only GET and POST are ever used by this API's routes;
#   PUT/DELETE/PATCH etc. are intentionally not allowed.
# - allow_headers: only the headers routes actually read -- Content-Type
#   for JSON/multipart bodies -- rather than every possible header.
DEFAULT_ALLOWED_ORIGINS = [
    "http://localhost:3000",     # local web frontend dev server
    "http://127.0.0.1:3000",
    "http://localhost:8080",     # `flutter run -d chrome` default port
    "http://127.0.0.1:8080",
]
_env_origins = os.environ.get("ALLOWED_ORIGINS")
origins = [o.strip() for o in _env_origins.split(",")] if _env_origins else DEFAULT_ALLOWED_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)

# ---------------------------------------------------------------------
# Model loading (in-memory, hot-swappable by /retrain and the watcher)
# ---------------------------------------------------------------------
_state = {"pipeline": None, "meta": None}
_retrain_status = {
    "last_auto_retrain_at": None,
    "last_auto_retrain_file": None,
    "last_auto_retrain_rows": None,
    "watcher_running": False,
}


def load_model():
    _state["pipeline"] = joblib.load(MODEL_PATH)
    _state["meta"] = joblib.load(META_PATH)


def _retrain_from_dataframe(new_df: pd.DataFrame) -> dict:
    """
    Shared retraining core used by BOTH the on-demand /retrain endpoint and
    the background auto-retrain watcher. Combines `new_df` with the
    persisted reference dataset, refits preprocessing + RandomForest,
    evaluates on a fresh holdout split, hot-swaps the live model, and
    persists everything to disk.
    """
    meta = _state["meta"]
    required_cols = set(meta["categorical"] + meta["numeric"] + [meta["target"]])
    missing = required_cols - set(new_df.columns)
    if missing:
        raise ValueError(f"Uploaded data is missing required columns: {sorted(missing)}")

    keep_cols = list(required_cols)
    new_df = new_df[keep_cols]

    if os.path.exists(REFERENCE_DATA_PATH):
        ref_df = pd.read_csv(REFERENCE_DATA_PATH)
        ref_df = ref_df[[c for c in keep_cols if c in ref_df.columns]]
        combined = pd.concat([ref_df, new_df], ignore_index=True).drop_duplicates()
    else:
        combined = new_df
    combined.to_csv(REFERENCE_DATA_PATH, index=False)

    y = combined[meta["target"]]
    X = combined[meta["categorical"] + meta["numeric"]]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    preprocessor = ColumnTransformer(
        transformers=[
            ("cat", OneHotEncoder(handle_unknown="ignore"), meta["categorical"]),
            ("num", StandardScaler(), meta["numeric"]),
        ]
    )
    regressor = RandomForestRegressor(n_estimators=200, max_depth=15, random_state=42, n_jobs=-1)
    new_pipeline = Pipeline(steps=[("preprocessor", preprocessor), ("regressor", regressor)])
    new_pipeline.fit(X_train, y_train)

    preds = new_pipeline.predict(X_test)
    test_r2 = float(r2_score(y_test, preds))
    test_rmse = float(mean_squared_error(y_test, preds) ** 0.5)

    joblib.dump(new_pipeline, MODEL_PATH)
    meta["best_model_name"] = "RandomForestRegressor (retrained)"
    joblib.dump(meta, META_PATH)
    _state["pipeline"] = new_pipeline
    _state["meta"] = meta

    return {"rows_used_for_training": len(combined), "test_r2": test_r2, "test_rmse": test_rmse}


async def _watch_for_new_data():
    """
    Background task: every POLL_INTERVAL_SECONDS, check data/incoming/ for
    CSV files dropped there by /data/ingest (or any external process --
    e.g. a streaming consumer batching events to disk) and automatically
    retrain on them, with no manual /retrain call needed. This is the
    "reactive to new data" path; /retrain remains available for an
    immediate, on-demand retrain.
    """
    _retrain_status["watcher_running"] = True
    os.makedirs(INCOMING_DIR, exist_ok=True)
    os.makedirs(PROCESSED_DIR, exist_ok=True)
    while True:
        try:
            csv_files = [f for f in os.listdir(INCOMING_DIR) if f.endswith(".csv")]
            for fname in csv_files:
                path = os.path.join(INCOMING_DIR, fname)
                try:
                    df = pd.read_csv(path)
                    result = _retrain_from_dataframe(df)
                    shutil.move(path, os.path.join(PROCESSED_DIR, fname))
                    _retrain_status["last_auto_retrain_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                    _retrain_status["last_auto_retrain_file"] = fname
                    _retrain_status["last_auto_retrain_rows"] = result["rows_used_for_training"]
                    print(f"[auto-retrain] processed {fname}: {result}")
                except Exception as exc:
                    print(f"[auto-retrain] failed on {fname}: {exc}")
        except Exception as exc:
            print(f"[auto-retrain] watcher error: {exc}")
        await asyncio.sleep(POLL_INTERVAL_SECONDS)


@app.on_event("startup")
async def on_startup():
    load_model()
    asyncio.create_task(_watch_for_new_data())


# ---------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------
@app.get("/", include_in_schema=False)
def root():
    """Redirect the bare domain to the Swagger UI."""
    return RedirectResponse(url="/docs")


@app.get("/health", response_model=HealthResponse, tags=["meta"])
def health():
    return HealthResponse(
        status="ok",
        model_loaded=_state["pipeline"] is not None,
        model_name=_state["meta"]["best_model_name"] if _state["meta"] else "unknown",
    )


def _row_to_frame(payload: PredictionInput) -> pd.DataFrame:
    meta = _state["meta"]
    data = payload.model_dump()
    # Enum -> plain string for the encoder
    for cat_col in meta["categorical"]:
        data[cat_col] = data[cat_col].value if hasattr(data[cat_col], "value") else data[cat_col]
    ordered_cols = meta["categorical"] + meta["numeric"]
    return pd.DataFrame([[data[c] for c in ordered_cols]], columns=ordered_cols)


@app.post("/predict", response_model=PredictionOutput, tags=["prediction"])
def predict(payload: PredictionInput):
    """Predict `count` for a single network connection record."""
    if _state["pipeline"] is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    X = _row_to_frame(payload)
    pred = _state["pipeline"].predict(X)[0]
    return PredictionOutput(predicted_count=float(pred), model_name=_state["meta"]["best_model_name"])


@app.post("/predict/batch", response_model=List[PredictionOutput], tags=["prediction"])
def predict_batch(payloads: List[PredictionInput]):
    """Predict `count` for a batch of network connection records."""
    if _state["pipeline"] is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    frames = [_row_to_frame(p) for p in payloads]
    X = pd.concat(frames, ignore_index=True)
    preds = _state["pipeline"].predict(X)
    name = _state["meta"]["best_model_name"]
    return [PredictionOutput(predicted_count=float(p), model_name=name) for p in preds]


@app.post("/retrain", response_model=RetrainResponse, tags=["training"])
async def retrain(file: UploadFile = File(..., description="CSV with the same feature columns plus a `count` target column")):
    """
    Trigger an IMMEDIATE, on-demand retrain using newly uploaded labeled
    data (synchronous -- the response only comes back once training and
    hot-swap are done). For a fire-and-forget, automatically-processed
    alternative, use POST /data/ingest instead.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file")

    raw = await file.read()
    try:
        new_df = pd.read_csv(io.BytesIO(raw))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Could not parse CSV: {exc}")

    try:
        result = _retrain_from_dataframe(new_df)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc))

    return RetrainResponse(
        status="success",
        rows_used_for_training=result["rows_used_for_training"],
        model_name=_state["meta"]["best_model_name"],
        test_r2=round(result["test_r2"], 4),
        test_rmse=round(result["test_rmse"], 4),
        message="Model retrained on combined reference + uploaded data and hot-swapped into the live API.",
    )


@app.post("/data/ingest", response_model=IngestResponse, tags=["training"])
async def ingest(file: UploadFile = File(..., description="CSV with new labeled data to queue for automatic retraining")):
    """
    Queue new labeled data for AUTOMATIC retraining -- this is the
    "reactive to new data" path. The file is saved to data/incoming/ and
    returns immediately; a background task (started at API startup) polls
    that folder every RETRAIN_POLL_SECONDS (default 30s) and retrains on
    any file it finds there, with no further manual action required.
    Simulates a streaming ingestion point: an external producer (e.g. a
    log shipper batching live traffic to CSV) can call this repeatedly and
    the model stays current on its own.
    """
    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file")

    os.makedirs(INCOMING_DIR, exist_ok=True)
    dest_name = f"{int(time.time())}_{file.filename}"
    dest_path = os.path.join(INCOMING_DIR, dest_name)
    raw = await file.read()
    with open(dest_path, "wb") as f:
        f.write(raw)

    return IngestResponse(
        status="queued",
        filename=dest_name,
        message=f"File queued. The background watcher retrains automatically within {POLL_INTERVAL_SECONDS}s.",
    )


@app.get("/retrain/status", response_model=RetrainStatusResponse, tags=["training"])
def retrain_status():
    """Info about the background auto-retrain watcher and its last run."""
    return RetrainStatusResponse(**_retrain_status)
