#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
GZIP_VERSION="1.13"
GZIP_REPO="https://ftp.gnu.org/gnu/gzip/gzip-${GZIP_VERSION}.tar.xz"

log "Starting Gzip build process..."
. fetch_archive $GZIP_REPO

log "Building Gzip"
./configure --host="$HOST"
make -j"$(nproc)"
verify_build gzip
