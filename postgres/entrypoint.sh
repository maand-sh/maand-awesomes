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

cert_src="/etc/patroni/certs"
cert_dir="/run/patroni/certs"
if [ -d "${cert_src}" ]; then
  mkdir -p "${cert_dir}"
  for name in ca.crt server.crt server.key zookeeper_client.crt zookeeper_client.key; do
    if [ -f "${cert_src}/${name}" ]; then
      cp "${cert_src}/${name}" "${cert_dir}/${name}"
    fi
  done
  chown -R postgres:postgres "${cert_dir}"
  chmod 0644 "${cert_dir}"/*.crt 2>/dev/null || true
  chmod 0600 "${cert_dir}"/*.key 2>/dev/null || true
fi

echo "Starting Patroni..."
exec gosu postgres patroni "${PATRONI_CONFIG}"
