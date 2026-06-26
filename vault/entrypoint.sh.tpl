#!/bin/sh
set -eu

mkdir -p /vault/data
chmod 700 /vault/data 2>/dev/null || true

exec vault "$@"
