#!/usr/bin/env python3
"""Shared ZooKeeper helpers for maand job commands."""

from __future__ import annotations

import os
import socket
import ssl

from maand import get_kv_value


def log(message: str) -> None:
    print(f"[zookeeper] {message}", flush=True)


def leader_ip() -> str:
    """First zookeeper worker by catalog position (server.1 / bootstrap node)."""
    return get_kv_value("maand/job/zookeeper", "worker_0").strip()


def zookeeper_workers() -> list[str]:
    return [
        ip.strip()
        for ip in get_kv_value("maand/job/zookeeper", "workers").split(",")
        if ip.strip()
    ]


def client_port() -> int:
    return int(get_kv_value("maand/bucket", "zookeeper_port_client"))


def default_cert_paths(name: str = "quorum") -> tuple[str, str, str]:
    cert_dir = os.path.join(os.path.dirname(__file__), "certs")
    return (
        os.path.join(cert_dir, f"{name}.crt"),
        os.path.join(cert_dir, f"{name}.key"),
        os.path.join(cert_dir, "ca.crt"),
    )


def _ssl_context(cert: str, key: str, ca: str) -> ssl.SSLContext:
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    ctx.load_cert_chain(cert, key)
    ctx.load_verify_locations(ca)
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_REQUIRED
    return ctx


def fetch_four_letter_word(
    host: str,
    port: int,
    command: bytes,
    timeout: float = 5,
    *,
    cert: str | None = None,
    key: str | None = None,
    ca: str | None = None,
) -> str | None:
    if cert is None or key is None or ca is None:
        cert, key, ca = default_cert_paths()
    ctx = _ssl_context(cert, key, ca)
    try:
        with socket.create_connection((host, port), timeout=timeout) as sock:
            with ctx.wrap_socket(sock, server_hostname=host) as ssock:
                ssock.sendall(command)
                chunks: list[bytes] = []
                while True:
                    part = ssock.recv(8192)
                    if not part:
                        break
                    chunks.append(part)
                return b"".join(chunks).decode(errors="replace")
    except OSError:
        return None


def is_four_letter_word_error(raw: str) -> bool:
    return "is not executed because it is not in the whitelist" in raw


def fetch_srvr(
    host: str,
    port: int,
    timeout: float = 5,
    *,
    cert: str | None = None,
    key: str | None = None,
    ca: str | None = None,
) -> str | None:
    return fetch_four_letter_word(
        host,
        port,
        b"srvr",
        timeout=timeout,
        cert=cert,
        key=key,
        ca=ca,
    )


def node_mode(stat: str) -> str | None:
    return parse_stat(stat).get("Mode")


def parse_stat(stat: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for line in stat.splitlines():
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()
    return fields


def server_label(host: str, workers: list[str]) -> str:
    try:
        return f"server.{workers.index(host) + 1}"
    except ValueError:
        return host


def node_endpoint(
    host: str,
    workers: list[str],
    port: int,
    stat: dict[str, str] | None = None,
) -> str:
    label = server_label(host, workers)
    mode = (stat or {}).get("Mode") or "?"
    zxid = (stat or {}).get("Zxid")
    parts = [f"{label} ({host}:{port}) state={mode}"]
    if zxid:
        parts.append(f"zxid={zxid}")
    return " ".join(parts)


def fetch_node_stat(
    host: str,
    port: int | None = None,
    timeout: float = 5,
    *,
    cert: str | None = None,
    key: str | None = None,
    ca: str | None = None,
) -> dict[str, str] | None:
    port = port if port is not None else client_port()
    raw = fetch_srvr(
        host,
        port,
        timeout=timeout,
        cert=cert,
        key=key,
        ca=ca,
    )
    if raw is None or is_four_letter_word_error(raw):
        return None
    fields = parse_stat(raw)
    if "Mode" not in fields:
        return None
    return fields


def active_leader_ip(
    workers: list[str] | None = None, port: int | None = None
) -> str | None:
    """ZooKeeper leader IP, or None if the ensemble is unreachable."""
    workers = workers if workers is not None else zookeeper_workers()
    port = port if port is not None else client_port()
    for host in workers:
        stat = fetch_srvr(host, port)
        if stat and (node_mode(stat) or "").lower() == "leader":
            return host
    return None


def is_cluster_running(workers: list[str] | None = None, port: int | None = None) -> bool:
    return active_leader_ip(workers, port) is not None
