"""
Pydantic request/response models.

Every numeric field's (ge, le) bounds are the empirical min/max observed in
the NSL-KDD training data (Train_data.csv) -- i.e. the realistic range the
underlying RandomForestRegressor was actually trained on. Values outside
these bounds are rejected with a 422 before they ever reach the model,
since a tree-based model given wildly out-of-distribution inputs will
silently extrapolate nonsense rather than error out on its own.

Categorical fields (`protocol_type`, `flag`, `service`) are enums built
from the exact category values seen in training. `Enum` (rather than a
plain constrained string) guarantees only known categories are accepted --
the one-hot encoder in the saved pipeline would otherwise silently ignore
unknown categories (`handle_unknown="ignore"`), which is desirable for
robustness at prediction time but not what we want at the API validation
layer, where a typo should surface immediately as a clear 422 error.
"""
from enum import Enum
from pydantic import BaseModel, Field, ConfigDict


class ProtocolType(str, Enum):
    icmp = "icmp"
    tcp = "tcp"
    udp = "udp"


class Flag(str, Enum):
    OTH = "OTH"
    REJ = "REJ"
    RSTO = "RSTO"
    RSTOS0 = "RSTOS0"
    RSTR = "RSTR"
    S0 = "S0"
    S1 = "S1"
    S2 = "S2"
    S3 = "S3"
    SF = "SF"
    SH = "SH"


class Service(str, Enum):
    IRC = "IRC"
    X11 = "X11"
    Z39_50 = "Z39_50"
    auth = "auth"
    bgp = "bgp"
    courier = "courier"
    csnet_ns = "csnet_ns"
    ctf = "ctf"
    daytime = "daytime"
    discard = "discard"
    domain = "domain"
    domain_u = "domain_u"
    echo = "echo"
    eco_i = "eco_i"
    ecr_i = "ecr_i"
    efs = "efs"
    exec_ = "exec"
    finger = "finger"
    ftp = "ftp"
    ftp_data = "ftp_data"
    gopher = "gopher"
    hostnames = "hostnames"
    http = "http"
    http_443 = "http_443"
    http_8001 = "http_8001"
    imap4 = "imap4"
    iso_tsap = "iso_tsap"
    klogin = "klogin"
    kshell = "kshell"
    ldap = "ldap"
    link = "link"
    login = "login"
    mtp = "mtp"
    name = "name"
    netbios_dgm = "netbios_dgm"
    netbios_ns = "netbios_ns"
    netbios_ssn = "netbios_ssn"
    netstat = "netstat"
    nnsp = "nnsp"
    nntp = "nntp"
    ntp_u = "ntp_u"
    other = "other"
    pm_dump = "pm_dump"
    pop_2 = "pop_2"
    pop_3 = "pop_3"
    printer = "printer"
    private = "private"
    red_i = "red_i"
    remote_job = "remote_job"
    rje = "rje"
    shell = "shell"
    smtp = "smtp"
    sql_net = "sql_net"
    ssh = "ssh"
    sunrpc = "sunrpc"
    supdup = "supdup"
    systat = "systat"
    telnet = "telnet"
    tim_i = "tim_i"
    time = "time"
    urh_i = "urh_i"
    urp_i = "urp_i"
    uucp = "uucp"
    uucp_path = "uucp_path"
    vmnet = "vmnet"
    whois = "whois"


class PredictionInput(BaseModel):
    """One network connection record. Field bounds mirror the training data."""

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "duration": 0,
                "protocol_type": "tcp",
                "service": "http",
                "flag": "SF",
                "src_bytes": 232,
                "dst_bytes": 8153,
                "land": 0,
                "wrong_fragment": 0,
                "urgent": 0,
                "hot": 0,
                "num_failed_logins": 0,
                "logged_in": 1,
                "num_compromised": 0,
                "root_shell": 0,
                "su_attempted": 0,
                "num_root": 0,
                "num_file_creations": 0,
                "num_shells": 0,
                "num_access_files": 0,
                "is_guest_login": 0,
                "srv_count": 5,
                "serror_rate": 0.0,
                "srv_serror_rate": 0.0,
                "rerror_rate": 0.0,
                "srv_rerror_rate": 0.0,
                "same_srv_rate": 1.0,
                "diff_srv_rate": 0.0,
                "srv_diff_host_rate": 0.0,
                "dst_host_count": 30,
                "dst_host_srv_count": 255,
                "dst_host_same_srv_rate": 1.0,
                "dst_host_diff_srv_rate": 0.0,
                "dst_host_same_src_port_rate": 0.03,
                "dst_host_srv_diff_host_rate": 0.04,
                "dst_host_serror_rate": 0.03,
                "dst_host_srv_serror_rate": 0.01,
                "dst_host_rerror_rate": 0.0,
                "dst_host_srv_rerror_rate": 0.01,
            }
        }
    )

    # -- categorical --
    protocol_type: ProtocolType = Field(..., description="Transport protocol")
    service: Service = Field(..., description="Network service on the destination")
    flag: Flag = Field(..., description="Status flag of the connection")

    # -- numeric: counts / bytes (integers) --
    duration: int = Field(..., ge=0, le=42862, description="Connection length in seconds")
    src_bytes: int = Field(..., ge=0, le=381_709_090, description="Bytes sent source->dest")
    dst_bytes: int = Field(..., ge=0, le=5_151_385, description="Bytes sent dest->source")
    land: int = Field(..., ge=0, le=1, description="1 if src/dst host+port are identical, else 0")
    wrong_fragment: int = Field(..., ge=0, le=3, description="Number of wrong fragments")
    urgent: int = Field(..., ge=0, le=1, description="Number of urgent packets")
    hot: int = Field(..., ge=0, le=77, description="Number of 'hot' indicators")
    num_failed_logins: int = Field(..., ge=0, le=4)
    logged_in: int = Field(..., ge=0, le=1, description="1 if successfully logged in")
    num_compromised: int = Field(..., ge=0, le=884)
    root_shell: int = Field(..., ge=0, le=1)
    su_attempted: int = Field(..., ge=0, le=2)
    num_root: int = Field(..., ge=0, le=975)
    num_file_creations: int = Field(..., ge=0, le=40)
    num_shells: int = Field(..., ge=0, le=1)
    num_access_files: int = Field(..., ge=0, le=8)
    is_guest_login: int = Field(..., ge=0, le=1)
    srv_count: int = Field(..., ge=1, le=511, description="Connections to same service in past 2s")

    # -- numeric: rates (floats, 0-1) --
    serror_rate: float = Field(..., ge=0.0, le=1.0)
    srv_serror_rate: float = Field(..., ge=0.0, le=1.0)
    rerror_rate: float = Field(..., ge=0.0, le=1.0)
    srv_rerror_rate: float = Field(..., ge=0.0, le=1.0)
    same_srv_rate: float = Field(..., ge=0.0, le=1.0)
    diff_srv_rate: float = Field(..., ge=0.0, le=1.0)
    srv_diff_host_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_count: int = Field(..., ge=0, le=255)
    dst_host_srv_count: int = Field(..., ge=0, le=255)
    dst_host_same_srv_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_diff_srv_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_same_src_port_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_srv_diff_host_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_serror_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_srv_serror_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_rerror_rate: float = Field(..., ge=0.0, le=1.0)
    dst_host_srv_rerror_rate: float = Field(..., ge=0.0, le=1.0)


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


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_name: str


class IngestResponse(BaseModel):
    status: str
    filename: str
    message: str


class RetrainStatusResponse(BaseModel):
    last_auto_retrain_at: str | None
    last_auto_retrain_file: str | None
    last_auto_retrain_rows: int | None
    watcher_running: bool
