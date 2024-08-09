#!/bin/bash
set -euo pipefail

# Configuration
TOYBOX_REPO="https://github.com/landley/toybox.git"
LOG_FILE="build_toybox.log"
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
log "Starting Toybox build process for aarch64 (static)"

# Clone Toybox repository
if [ ! -d "toybox" ]; then
    log "Cloning Toybox repository"
    git clone --depth=1 "$TOYBOX_REPO"
    cd toybox
else
    log "Toybox directory already exists, updating"
    cd toybox
    git pull
fi

# Build Toybox
log "Building Toybox"
CROSS_COMPILE=aarch64-linux-musleabi- LDFLAGS=--static make defconfig toybox

# Verify build
if [ -f "toybox" ]; then
    log "Toybox built successfully"
    cp toybox "$BINARIES_DIR/toybox"
    log "Toybox binary copied to $BINARIES_DIR/toybox"
else
    log "Toybox build failed"
    exit 1
fi

log "Toybox build process completed"
