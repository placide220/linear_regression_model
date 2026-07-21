# NSL-KDD Connection-Count Regressor API

FastAPI service that wraps the best regression model from Task 1
(RandomForestRegressor, test R² = 0.991) and exposes it as a REST API,
plus a `/retrain` endpoint for updating the model with new data.

## Project structure
```
api/
├── app/
│   ├── __init__.py
│   ├── main.py        # FastAPI app: routes, CORS, model loading
│   └── schemas.py      # Pydantic request/response models (types + ranges)
├── models/
│   ├── best_model.joblib      # saved sklearn Pipeline (preprocessing + regressor)
│   └── model_metadata.joblib  # feature lists, target name, model name
├── data/
│   └── reference_train_data.csv   # baseline training data used by /retrain
├── requirements.txt
└── README.md
```

## 1. Run locally

```bash
cd api
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
uvicorn prediction:app --reload
```

Open **http://127.0.0.1:8000/docs** for the interactive Swagger UI, or
**http://127.0.0.1:8000/redoc** for ReDoc.

> This sandbox has no outbound network access, so I could not `pip install`
> fastapi/uvicorn and run a live server here to smoke-test it end-to-end.
> The code is syntax-checked and the request/response logic mirrors the
> exact preprocessing used in the training notebook, but **please run it
> locally yourself first** (steps above) and hit `/docs` to try a real
> request before you deploy, in case anything needs a small tweak on your
> machine/Python version.

### Quick test with curl
```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "duration": 0, "protocol_type": "tcp", "service": "http", "flag": "SF",
    "src_bytes": 232, "dst_bytes": 8153, "land": 0, "wrong_fragment": 0,
    "urgent": 0, "hot": 0, "num_failed_logins": 0, "logged_in": 1,
    "num_compromised": 0, "root_shell": 0, "su_attempted": 0, "num_root": 0,
    "num_file_creations": 0, "num_shells": 0, "num_access_files": 0,
    "is_guest_login": 0, "srv_count": 5, "serror_rate": 0.0,
    "srv_serror_rate": 0.0, "rerror_rate": 0.0, "srv_rerror_rate": 0.0,
    "same_srv_rate": 1.0, "diff_srv_rate": 0.0, "srv_diff_host_rate": 0.0,
    "dst_host_count": 30, "dst_host_srv_count": 255,
    "dst_host_same_srv_rate": 1.0, "dst_host_diff_srv_rate": 0.0,
    "dst_host_same_src_port_rate": 0.03, "dst_host_srv_diff_host_rate": 0.04,
    "dst_host_serror_rate": 0.03, "dst_host_srv_serror_rate": 0.01,
    "dst_host_rerror_rate": 0.0, "dst_host_srv_rerror_rate": 0.01
  }'
```

## 2. Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/` | redirects to `/docs` |
| GET | `/health` | liveness + which model is currently loaded |
| POST | `/predict` | single-record prediction |
| POST | `/predict/batch` | list of records -> list of predictions |
| POST | `/retrain` | upload a CSV (features + `count` column) to retrain **immediately** and hot-swap the live model |
| POST | `/data/ingest` | upload a CSV to **queue** for automatic retraining (no immediate call needed) |
| GET | `/retrain/status` | info about the background auto-retrain watcher and its last run |

`/predict` request/response types and numeric ranges are enforced by
`app/schemas.py` (Pydantic `BaseModel` + `Field(ge=..., le=...)`), using the
exact min/max observed in the original training data — see the docstring
at the top of that file for the reasoning.

## 3. CORS

Configured in `prediction.py`, with **no wildcard on any setting**:

- **`allow_origins`** — an explicit allowlist (defaults to common local dev
  origins: `localhost:3000`, `localhost:8080`), not `"*"`. The Swagger UI
  is served from the API's own origin so it needs no CORS entry at all;
  the allowlist exists for a *separate* browser-based web client (e.g. a
  Flutter **web** build), not for Swagger. The Flutter **mobile** app from
  Task 3 is a native HTTP client, not a browser, so CORS doesn't apply to
  it regardless of this setting. Override with the `ALLOWED_ORIGINS` env
  var (comma-separated) to point at your actual deployed frontend domain,
  e.g. `ALLOWED_ORIGINS=https://myfrontend.com`.
- **`allow_credentials=False`** — the API is stateless (no cookies/sessions),
  so there's nothing to send credentials for.
- **`allow_methods=["GET", "POST"]`** — only the verbs this API's routes
  actually use.
- **`allow_headers=["Content-Type"]`** — only the header routes actually
  read (JSON/multipart bodies).

Full reasoning is in the code comments directly above
`app.add_middleware(CORSMiddleware...)` in `prediction.py`.

## 4. Deploy to Render (free tier)

1. Push this `api/` folder to a **GitHub repo** (Render deploys from Git).
2. In the [Render dashboard](https://dashboard.render.com/): **New +** → **Web Service** → connect the repo.
3. Settings:
   - **Root Directory:** `summative/API`
   - **Runtime:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn prediction:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** Free
4. Click **Create Web Service**. Render will build and deploy; you'll get a
   public URL like `https://your-service-name.onrender.com`.
5. Your Swagger UI is then live at:
   **`https://your-service-name.onrender.com/docs`**

> Note: Render's free tier has an **ephemeral filesystem** — anything
> `/retrain` writes to `models/` or `data/` will be lost on redeploy or
> when the free instance spins down after inactivity. That's fine for
> demoing the retrain endpoint, but for a persistent production setup
> you'd add a Render **persistent disk** (paid) or write the updated model
> to external storage (e.g. S3) instead.

## 5. Retraining with new/streamed data

There are **two** retraining paths, sharing the same underlying logic
(`_retrain_from_dataframe` in `prediction.py`):

### a) Immediate, on-demand — `POST /retrain`
Synchronous: the response only returns once retraining is complete.
```bash
curl -X POST http://127.0.0.1:8000/retrain \
  -F "file=@/path/to/new_labeled_data.csv"
```
1. Combines the upload with the existing reference dataset.
2. Refits the full preprocessing + `RandomForestRegressor` pipeline.
3. Evaluates on a held-out split and returns the new test R²/RMSE.
4. Hot-swaps the new pipeline into the running API (no restart needed) and
   persists it to `models/best_model.joblib`.

### b) Automatic / reactive — `POST /data/ingest` + background watcher
This is the "the model updates itself when new data shows up" path, with
**no manual retrain call required**:
```bash
curl -X POST http://127.0.0.1:8000/data/ingest \
  -F "file=@/path/to/new_labeled_data.csv"
# -> {"status": "queued", ...}
```
The file is dropped into `data/incoming/`. A background `asyncio` task,
started automatically when the API boots (`on_startup`), polls that folder
every `RETRAIN_POLL_SECONDS` (default 30s, configurable via env var) and,
if it finds a file, retrains on it and hot-swaps the model — exactly the
same as `/retrain`, just triggered by the *presence of new data* rather
than by a human explicitly asking for a retrain. Processed files move to
`data/processed/`. Check progress any time with:
```bash
curl http://127.0.0.1:8000/retrain/status
```
This models a real streaming setup: an external producer (a log shipper,
a Kafka consumer batching events to CSV, etc.) can call `/data/ingest`
repeatedly and the model stays current on its own.
