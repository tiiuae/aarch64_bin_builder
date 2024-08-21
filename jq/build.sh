#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
export JQ_VERSION="1.7.1"
export JQ_URL="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz"

log "Starting JQ build process..."
. fetch_archive $JQ_URL

log "Building JQ"
./configure --host="$HOST" --with-oniguruma=builtin
make LDFLAGS="-all-static" -j"$(nproc)"
verify_build jq
