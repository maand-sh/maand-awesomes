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

if [ "$(id -u)" != "0" ]; then
  echo "patroni entrypoint must run as root to prepare PGDATA; use container default user"
  exit 1
fi

mkdir -p "${PGDATA_ROOT}" "${PGDATA}"
chown -R postgres:postgres "${PGDATA_ROOT}"
chmod 700 "${PGDATA_ROOT}"
if [ -d "${PGDATA}" ]; then
  chmod 700 "${PGDATA}"
fi

echo "Starting Patroni..."
exec gosu postgres patroni "${PATRONI_CONFIG}"
