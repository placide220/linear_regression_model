"""
Pydantic request/response models.

This API was simplified from an initial 38-feature version down to just
the 4 fields below, based on Random Forest feature-importance analysis
(see the notebook, Section 11): `same_srv_rate` and `srv_count` alone
account for ~90% of the model's predictive weight, and together with
`dst_host_diff_srv_rate` and `diff_srv_rate` they capture ~98.3% test R^2
-- within 0.8 points of the full 38-feature model's 0.991. Dropping the
other 34 near-zero-importance features (including all 3 categorical
columns) costs almost nothing in accuracy while making the API and the
Flutter form dramatically easier to fill in and test.

Numeric field bounds mirror the empirical min/max observed in the
original NSL-KDD training data.
"""
from pydantic import BaseModel, Field, ConfigDict


class PredictionInput(BaseModel):
    """The 4 features the deployed model actually relies on."""

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "same_srv_rate": 1.0,
                "srv_count": 5,
                "dst_host_diff_srv_rate": 0.0,
                "diff_srv_rate": 0.0,
            }
        }
    )

    same_srv_rate: float = Field(
        ..., ge=0.0, le=1.0,
        description="% of connections to the same service as the current one (past 2s). Most important feature (~52% of model weight)."
    )
    srv_count: int = Field(
        ..., ge=1, le=511,
        description="Number of connections to the same service in the past 2s. 2nd most important feature (~38% of model weight)."
    )
    dst_host_diff_srv_rate: float = Field(
        ..., ge=0.0, le=1.0,
        description="% of connections to the destination host that were to different services (~5% of model weight)."
    )
    diff_srv_rate: float = Field(
        ..., ge=0.0, le=1.0,
        description="% of connections to different services in the past 2s (~2% of model weight)."
    )


class PredictionOutput(BaseModel):
    predicted_count: float = Field(..., description="Predicted number of connections to the same host in the past 2s")
    model_name: str


class RetrainResponse(BaseModel):
    status: str
    rows_used_for_training: int
    model_name: str
    test_r2: float
    test_rmse: float
    message: str


class IngestResponse(BaseModel):
    status: str
    filename: str
    message: str


class RetrainStatusResponse(BaseModel):
    last_auto_retrain_at: str | None
    last_auto_retrain_file: str | None
    last_auto_retrain_rows: int | None
    watcher_running: bool


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_name: str
