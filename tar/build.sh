#!/bin/bash
set -euo pipefail

# Configuration
TAR_VERSION="1.35"
TAR_REPO="https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.xz"
LOG_FILE="build_tar.log"
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
log "Starting Tar build process for aarch64 (static)"

# Clone Tar repository
if [ ! -d "tar-${TAR_VERSION}" ]; then
    log "Fetching Tar code"
    wget $TAR_REPO
    tar xfv tar-${TAR_VERSION}.tar.xz
else
    log "Tar directory already exists, skipping"
fi

# Build Tar
log "Building Tar"
cd tar-${TAR_VERSION}
CC=/opt/cross/bin/aarch64-linux-musleabi-gcc \
    CFLAGS=-static \
    LDFLAGS="-static -s" \
    ./configure --host=aarch64-linux-musleabi
make -j"$(nproc)"

# Verify build
if [ -f "src/tar" ]; then
    log "Tar built successfully"
    cp src/tar "$BINARIES_DIR/tar"
    log "Tar binary copied to $BINARIES_DIR/tar"
else
    log "Tar build failed"
    exit 1
fi

log "Tar build process completed"
