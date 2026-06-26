#!/usr/bin/env python3
"""Shared Vault helpers for maand job commands.

The cluster is bootstrapped entirely through the default deploy path:

  - deploy_parallel_count = 1 starts nodes one at a time in deploy_order
    (catalog/position order -> leader vault_0 first).
  - after_allocation_started (command_node_up) brings each node to "operational"
    right after its container starts: the leader initializes the cluster and stores
    unseal keys in KV; each follower auto-joins via Raft retry_join (config.hcl)
    and is then unsealed.

No orchestrator semaphore and no job_control: batching guarantees ordering and
each invocation only operates on its own ALLOCATION_IP. Unseal keys/root token the
leader writes to KV in one batch are visible to follower batches in the same
deploy session.
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request

import maand

KEY_SHARES = 5
KEY_THRESHOLD = 3
VAULT_CONTAINER = "vault"
VAULT_ADDR = "http://127.0.0.1:8200"
API_PORT = 8200

API_TIMEOUT = 180
SSH_TIMEOUT = 90
LOG_EVERY = 10

# vars/job/<vault> flags describing cluster state.
KV_INITIALIZED = "cluster_initialized"
KV_LEADER_IP = "cluster_leader_ip"
KV_BOOTSTRAPPED = "cluster_bootstrapped"
KV_BOOTSTRAPPED_AT = "cluster_bootstrapped_at"


def log(message: str) -> None:
    print(f"[vault] {message}", flush=True)


# --- KV / topology -----------------------------------------------------------

def leader_ip() -> str:
    """First vault worker by position == designated bootstrap leader."""
    return maand.get_kv_value("maand/worker", "vault_0")


def vault_workers() -> list[str]:
    return maand.get_kv_value("maand/worker", "vault_workers").split(",")


def _job_ns(prefix: str) -> str:
    return f"{prefix}/job/{maand.job_name()}"


def get_job_var(key: str) -> str | None:
    response = maand.get_store_value(_job_ns("vars"), key)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()["value"]


def get_job_secret(key: str) -> str | None:
    response = maand.get_store_value(_job_ns("secrets"), key)
    if response.status_code == 404:
        return None
    response.raise_for_status()
    return response.json()["value"]


# --- Vault API helpers -------------------------------------------------------

def _vault_api_request(
    method: str,
    worker_ip: str,
    endpoint: str,
    *,
    data: dict | None = None,
    token: str | None = None,
    timeout: int = 5,
) -> dict:
    """Make an HTTP request to Vault API.

    Args:
        method: HTTP method (GET, PUT, POST, DELETE).
        worker_ip: Vault node IP address.
        endpoint: API endpoint (e.g., "/v1/sys/health", "/v1/sys/init").
        data: Optional JSON request body.
        token: Optional Vault token for authentication.
        timeout: Request timeout in seconds.

    Returns:
        Parsed JSON response.

    Raises:
        RuntimeError: On HTTP errors or request failures.
    """
    url = f"http://{worker_ip}:{API_PORT}{endpoint}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["X-Vault-Token"] = token

    body = None
    if data:
        body = json.dumps(data).encode("utf-8")

    try:
        request = urllib.request.Request(
            url, data=body, headers=headers, method=method
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            response_data = response.read().decode()
            return json.loads(response_data) if response_data else {}
    except urllib.error.HTTPError as exc:
        # Try to parse error response; some status codes are expected.
        try:
            error_data = json.loads(exc.read().decode())
        except (json.JSONDecodeError, UnicodeDecodeError):
            error_data = {}
        raise RuntimeError(
            f"{worker_ip}: {method} {endpoint} failed (HTTP {exc.code}): "
            f"{error_data.get('errors', [exc.reason])}"
        ) from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(
            f"{worker_ip}: {method} {endpoint} request failed: {exc}"
        ) from exc


def vault_status(worker_ip: str) -> dict:
    """Get Vault status via /v1/sys/health API.

    Returns initialized and sealed status. Note: HTTP 429/472/473/501/503 may be
    returned even on failure; these carry JSON describing seal/standby state.
    """
    url = f"http://{worker_ip}:{API_PORT}/v1/sys/health"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            return data
    except urllib.error.HTTPError as exc:
        # 429/472/473/501/503 carry JSON describing seal/standby state.
        if exc.code in (429, 472, 473, 501, 503):
            try:
                return json.loads(exc.read().decode())
            except json.JSONDecodeError:
                # Return minimal status if we can't parse JSON response.
                return {"sealed": True, "initialized": False}
        # For other errors, try to parse error response or raise.
        try:
            error_data = json.loads(exc.read().decode())
            return error_data
        except (json.JSONDecodeError, UnicodeDecodeError):
            raise RuntimeError(
                f"{worker_ip}: vault_status failed (HTTP {exc.code})"
            ) from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        raise RuntimeError(
            f"{worker_ip}: vault_status request failed: {exc}"
        ) from exc


# --- Readiness probes --------------------------------------------------------

def fetch_health(worker_ip: str) -> dict | None:
    url = f"http://{worker_ip}:{API_PORT}/v1/sys/health"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as exc:
        # 429/472/473/501/503 carry a JSON body describing seal/standby state.
        if exc.code in (429, 472, 473, 501, 503):
            try:
                return json.loads(exc.read().decode())
            except json.JSONDecodeError:
                return None
        return None
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError):
        return None


def fetch_leader(worker_ip: str) -> dict | None:
    """GET /v1/sys/leader on a node, or None if unreachable."""
    url = f"http://{worker_ip}:{API_PORT}/v1/sys/leader"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            return json.loads(response.read().decode())
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, json.JSONDecodeError):
        return None


def active_leader_ip() -> str | None:
    """IP of the current active Raft leader (queried live), or None if unknown."""
    for worker_ip in vault_workers():
        info = fetch_leader(worker_ip)
        if not info:
            continue
        # leader_address looks like "http://10.48.200.1:8201".
        addr = info.get("leader_address") or ""
        host = addr.split("//", 1)[-1].rsplit(":", 1)[0].strip()
        if host:
            return host
    return None


def _wait(predicate, message: str, timeout: int):
    deadline = time.time() + timeout
    start = last = time.time()
    while time.time() < deadline:
        value = predicate()
        if value:
            return value
        now = time.time()
        if now - last >= LOG_EVERY:
            log(f"{message} ({int(now - start)}s elapsed)")
            last = now
        time.sleep(2)
    raise TimeoutError(f"{message}: timed out after {timeout}s")


def wait_for_container(worker_ip: str, timeout: int = API_TIMEOUT) -> None:
    def running():
        result = maand.run_ssh(
            worker_ip,
            "docker ps --format '{{.Names}}'",
            check=False,
            timeout=30,
        )
        names = (result.stdout or "").split()
        return result.returncode == 0 and VAULT_CONTAINER in names

    _wait(running, f"{worker_ip}: waiting for vault container", timeout)


def wait_for_api(worker_ip: str, timeout: int = API_TIMEOUT) -> dict:
    return _wait(
        lambda: fetch_health(worker_ip),
        f"{worker_ip}: waiting for vault API",
        timeout,
    )


def is_operational(worker_ip: str) -> bool:
    health = fetch_health(worker_ip)
    return bool(health and health.get("initialized") and not health.get("sealed"))


def wait_operational(worker_ip: str, timeout: int = API_TIMEOUT) -> None:
    _wait(
        lambda: is_operational(worker_ip),
        f"{worker_ip}: waiting to become operational",
        timeout,
    )


# --- Bootstrap primitives ----------------------------------------------------

def store_init_secrets(init_data: dict) -> None:
    keys = extract_unseal_keys(init_data)
    for index, key in enumerate(keys, start=1):
        maand.put_job_secret(f"unseal_key_{index}", key).raise_for_status()
    maand.put_job_secret("root_token", init_data["root_token"]).raise_for_status()
    maand.put_job_variable("cluster_key_shares", str(KEY_SHARES)).raise_for_status()
    maand.put_job_variable("cluster_key_threshold", str(KEY_THRESHOLD)).raise_for_status()


def extract_unseal_keys(init_data: dict) -> list[str]:
    """Return unseal/recovery keys from Vault init response across versions.

    Shamir init typically returns `keys_base64`/`keys`; some payloads expose
    `unseal_keys_*`. Auto-unseal setups may only return `recovery_keys_*`.
    """
    candidates = (
        "unseal_keys_b64",
        "keys_base64",
        "unseal_keys_hex",
        "keys",
        "recovery_keys_b64",
        "recovery_keys_hex",
    )
    for field in candidates:
        values = init_data.get(field)
        if isinstance(values, list) and values:
            return [str(v) for v in values if str(v).strip()]
    return []


def mark_initialized(leader: str) -> None:
    maand.put_job_variable(KV_INITIALIZED, "true").raise_for_status()
    maand.put_job_variable(KV_LEADER_IP, leader).raise_for_status()


def mark_bootstrapped(leader: str) -> None:
    now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    maand.put_job_variable(KV_BOOTSTRAPPED, "true").raise_for_status()
    maand.put_job_variable(KV_BOOTSTRAPPED_AT, now).raise_for_status()


def init_leader(leader: str) -> list[str]:
    """Initialize the leader and return unseal keys for immediate local unseal.

    Secrets are still published to maand KV for followers and future operations.
    """
    log(f"{leader}: initializing vault cluster")
    init_data = _vault_api_request(
        "PUT",
        leader,
        "/v1/sys/init",
        data={
            "secret_shares": KEY_SHARES,
            "secret_threshold": KEY_THRESHOLD,
        },
        timeout=30,
    )
    keys = extract_unseal_keys(init_data)
    if len(keys) < KEY_THRESHOLD:
        key_fields = sorted(
            k for k in init_data.keys() if "key" in k.lower() or k == "root_token"
        )
        raise RuntimeError(
            f"{leader}: init response returned {len(keys)} unseal/recovery keys; "
            f"need at least {KEY_THRESHOLD}; fields={key_fields}"
        )

    store_init_secrets(init_data)
    mark_initialized(leader)
    log(f"{leader}: init complete; unseal keys stored in KV")
    return keys


def unseal_node(worker_ip: str, *, unseal_keys: list[str] | None = None) -> None:
    status = vault_status(worker_ip)
    if not status.get("sealed"):
        return

    try:
        required = int(status.get("t") or KEY_THRESHOLD)
    except (TypeError, ValueError):
        required = KEY_THRESHOLD

    if unseal_keys is not None and len(unseal_keys) < required:
        raise RuntimeError(
            f"{worker_ip}: received {len(unseal_keys)} inline unseal keys; "
            f"need at least {required}"
        )

    for index in range(1, required + 1):
        key = unseal_keys[index - 1] if unseal_keys is not None else get_job_secret(f"unseal_key_{index}")
        if not key:
            raise RuntimeError(
                f"missing secrets/job/{maand.job_name()}/unseal_key_{index}; "
                "leader must initialize the cluster first"
            )
        resp = _vault_api_request(
            "PUT",
            worker_ip,
            "/v1/sys/unseal",
            data={"key": key},
            timeout=10,
        )

        # Vault may need a short moment to apply unseal progress; stop early if done.
        if not resp.get("sealed", True):
            break

    # Avoid false negatives from immediate status checks right after final key.
    _wait(
        lambda: (h := fetch_health(worker_ip)) and not h.get("sealed"),
        f"{worker_ip}: waiting to become unsealed",
        45,
    )

    latest = vault_status(worker_ip)
    if latest.get("sealed"):
        raise RuntimeError(
            f"{worker_ip}: still sealed after unseal attempts "
            f"(progress={latest.get('progress')}, threshold={latest.get('t')}, shares={latest.get('n')})"
        )
    log(f"{worker_ip}: unsealed")


def join_raft(worker_ip: str, leader: str) -> None:
    """Idempotent Raft join (config.hcl retry_join usually handles this already)."""
    try:
        _vault_api_request(
            "PUT",
            worker_ip,
            "/v1/sys/storage/raft/join",
            data={"leader_api_addr": f"http://{leader}:{API_PORT}"},
            timeout=10,
        )
    except RuntimeError as exc:
        # Raft join might fail if node is already joined or has a different leader.
        # Check if it's already a peer and return success if so.
        error_msg = str(exc).lower()
        if "already" in error_msg or "peer" in error_msg:
            log(f"{worker_ip}: already part of raft cluster")
            return
        raise
    log(f"{worker_ip}: joined raft cluster")


def ensure_keys_present() -> None:
    if get_job_secret("unseal_key_1") is None:
        raise RuntimeError(
            "leader has not published unseal keys yet; cannot unseal followers"
        )
