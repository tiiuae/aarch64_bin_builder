#!/bin/bash
set -euo pipefail

# Configuration
OPENSSL_VERSION="3.3.1"
LOG_FILE="build_openssl.log"
BINARIES_DIR="/repo/binaries"

# Function for logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function for error handling
handle_error() {
    log "Error occurred on line $1"
    exit 1
}

build_openssl() {
    cd /tmp

    # Download
    curl -LOk https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}

    # Configure
    LDFLAGS='-s -static' \
        CFLAGS='-static' \
        ./Configure no-shared \
        linux-aarch64 \
        no-tests \
        --cross-compile-prefix=/opt/cross/bin/aarch64-linux-musleabi-

    # Build
    make -j"$(nproc)"
    log "Finished building static OpenSSL"
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting Openssl build process for aarch64 (static)"

build_openssl

# Verify build
if [ -f "apps/openssl" ]; then
    log "OpenSSL built successfully"
    cp apps/openssl "$BINARIES_DIR/openssl"
    log "OpenSSL binary copied to $BINARIES_DIR"
else
    log "OpenSSL build failed"
    exit 1
fi

log "OpenSSL build process completed"
