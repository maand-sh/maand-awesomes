#!/usr/bin/env bash
set -euo pipefail

# Cassandra PEM keystore must be cert+key in one file. maand deploys internode.crt/key
# separately; build the combined PEM on a writable path (certs mount is read-only).
TLS_DIR=/var/lib/cassandra/tls
mkdir -p "${TLS_DIR}"

if [ ! -f /conf/certs/internode.crt ] || [ ! -f /conf/certs/internode.key ]; then
  echo "missing /conf/certs/internode.crt or internode.key" >&2
  exit 1
fi

cat /conf/certs/internode.crt /conf/certs/internode.key > "${TLS_DIR}/internode.pem"
cp /conf/certs/ca.crt "${TLS_DIR}/ca.crt"
chmod 600 "${TLS_DIR}/internode.pem"
chmod 644 "${TLS_DIR}/ca.crt"

exec /usr/local/bin/docker-entrypoint.sh cassandra -f
