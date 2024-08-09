#!/bin/bash
set -euo pipefail

# Configuration
BUSYBOX_REPO="https://www.busybox.net/downloads/busybox-1.36.1.tar.bz2"
LOG_FILE="build_busybox.log"
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
log "Starting busybox build process for aarch64 (static)"

# Clone busybox repository
if [ ! -d "busybox" ]; then
    log "Cloning busybox repository"
    wget -qO- "$BUSYBOX_REPO" | tar -xvj
    cd busybox-1.36.1
else
    log "busybox directory already exists, skipping"
    cd busybox-1.36.1
fi

# Build busybox
log "Building busybox"
CROSS_COMPILE=aarch64-linux-musleabi- LDFLAGS=--static make defconfig busybox

# Verify build
if [ -f "busybox" ]; then
    log "busybox built successfully"
    cp busybox "$BINARIES_DIR/busybox"
    log "busybox binary copied to $BINARIES_DIR/busybox"
else
    log "busybox build failed"
    exit 1
fi

log "busybox build process completed"
