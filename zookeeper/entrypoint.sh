#!/usr/bin/env bash
set -euo pipefail

# ZooKeeper PEM keystore must be cert+key in one file. maand deploys quorum.crt/key
# separately; build the combined PEM on a writable path (certs mount is read-only).
# The same PEM is used for quorum TLS and the TLS-only client port.
TLS_DIR=/data/tls
mkdir -p "${TLS_DIR}"

if [ ! -f /conf/certs/quorum.crt ] || [ ! -f /conf/certs/quorum.key ]; then
  echo "missing /conf/certs/quorum.crt or quorum.key" >&2
  exit 1
fi

cat /conf/certs/quorum.crt /conf/certs/quorum.key > "${TLS_DIR}/quorum.pem"
cp /conf/certs/ca.crt "${TLS_DIR}/ca.crt"
chmod 600 "${TLS_DIR}/quorum.pem"
chmod 644 "${TLS_DIR}/ca.crt"

exec /docker-entrypoint.sh zkServer.sh start-foreground
