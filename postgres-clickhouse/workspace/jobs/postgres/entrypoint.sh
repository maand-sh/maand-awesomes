#!/usr/bin/env bash

set -exu -o pipefail

if [ "$1" != "patroni" ]; then
  exec gosu postgres "$@"
fi

echo "Checking if patroni configuration file exists..."
if [ -z "${PATRONI_CONFIG:-}" ]; then
  echo "PATRONI_CONFIG is not set. Exiting."
  exit 1
fi
if [ ! -f "${PATRONI_CONFIG}" ]; then
  echo "Patroni configuration file ${PATRONI_CONFIG} does not exist. Exiting."
  exit 1
fi

PGDATA="${PGDATA:-/var/lib/postgresql/pgdata/data}"
PGDATA_ROOT="$(dirname "${PGDATA}")"
TLS_DIR="${PGDATA_ROOT}/tls"
if [ -d "${PGDATA}.failed" ]; then
  rm -rf "${PGDATA}.failed"
fi
mkdir -p "${PGDATA_ROOT}" "${PGDATA}"
if [ -d /etc/patroni/certs ]; then
  mkdir -p "${TLS_DIR}"
  cp /etc/patroni/certs/ca.crt /etc/patroni/certs/server.crt "${TLS_DIR}/"
  cp /etc/patroni/certs/server.key "${TLS_DIR}/"
  chmod 0644 "${TLS_DIR}/ca.crt" "${TLS_DIR}/server.crt"
  chmod 0600 "${TLS_DIR}/server.key"
fi
chown -R postgres:postgres "${PGDATA_ROOT}"
chmod 700 "${PGDATA_ROOT}" "${PGDATA}"

echo "Starting Patroni..."
exec gosu postgres patroni "${PATRONI_CONFIG}"
