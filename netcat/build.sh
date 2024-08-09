#!/bin/bash
set -euo pipefail

# Configuration
NETCAT_REPO="https://sourceforge.net/projects/netcat/files/latest/download"
LOG_FILE="build_netcat.log"
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
log "Starting netcat build process for aarch64 (static)"

# Clone netcat repository
if [ ! -d "netcat" ]; then
    log "Fetching netcat repository"
    wget -qO- "$NETCAT_REPO" | tar xvj
    cd netcat-0.7.1
else
    log "Netcat directory already exists, updating"
    cd netcat-0.7.1
    git pull
fi

# Build netcat
log "Building Netcat"

wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
chmod +x config.sub
./configure --host=aarch64-linux-musl CC=aarch64-linux-musleabi-gcc CXX=aarch64-linux-musleabi-g++ LDFLAGS="-s -static" CFLAGS=-static
make -j"$(nproc)"

# Verify build
if [ -f "src/netcat" ]; then
    log "Netcat built successfully"
    cp src/netcat "$BINARIES_DIR/netcat"
    log "Netcat binary copied to $BINARIES_DIR/netcat"
else
    log "Netcat build failed"
    exit 1
fi

log "Netcat build process completed"
