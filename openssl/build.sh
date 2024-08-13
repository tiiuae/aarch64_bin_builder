#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
OPENSSL_VERSION="3.3.1"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

log "Starting OpenSSL build process..."
. fetch_archive $OPENSSL_URL
log "Building OpenSSL"
LDFLAGS='-s -static' \
    CFLAGS='-static' \
    ./Configure no-shared \
    linux-aarch64 \
    no-tests \
    --cross-compile-prefix=/opt/cross/bin/aarch64-linux-musleabi-
make -j"$(nproc)"
verify_build -b "openssl" -p "apps"
