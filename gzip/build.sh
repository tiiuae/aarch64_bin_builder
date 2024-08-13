#!/bin/bash
set -euo pipefail

# Configuration
GZIP_VERSION="1.13"
GZIP_REPO="https://ftp.gnu.org/gnu/gzip/gzip-${GZIP_VERSION}.tar.xz"
LOG_FILE="build_gzip.log"
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

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting Gzip build process for aarch64 (static)"

# Clone Gzip repository
if [ ! -d "gzip-${GZIP_VERSION}" ]; then
    log "Fetching Gzip code"
    wget $GZIP_REPO
    tar xfv gzip-${GZIP_VERSION}.tar.xz
else
    log "Gzip directory already exists, skipping"
fi

# Build Gzip
log "Building Gzip"
cd gzip-${GZIP_VERSION}
CC=/opt/cross/bin/aarch64-linux-musleabi-gcc \
    CFLAGS=-static \
    LDFLAGS="-static -s" \
    ./configure --host=aarch64-linux-musleabi
make -j"$(nproc)"

# Verify build
if [ -f "gzip" ]; then
    log "Gzip built successfully"
    cp gzip "$BINARIES_DIR/gzip"
    log "Gzip binary copied to $BINARIES_DIR/gzip"
else
    log "Gzip build failed"
    exit 1
fi

log "Gzip build process completed"
