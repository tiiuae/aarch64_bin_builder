#!/bin/bash
set -euo pipefail

# Configuration
NETTOOLS_REPO="https://github.com/ecki/net-tools"
LOG_FILE="build_nettools.log"
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

build_nettools() {
    cd /tmp

    # Clone Nettools repository
    if [ ! -d "net-tools" ]; then
        log "Cloning Nettools repository"
        git clone --depth=1 "$NETTOOLS_REPO"
        cd net-tools
    else
        log "Nettools directory already exists, updating"
        cd net-tools
        git pull
    fi

    # Set the default options for all 44 options..
    printf "%0.s\n" {1..44} | make config

    CC=aarch64-linux-musleabi-gcc \
        CFLAGS="-I/usr/include -I/usr/include/bluetooth" \
        LDFLAGS="--static -s" \
        make -j"$(nproc)"

}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting Nettools build process for aarch64 (static)"

build_nettools

# Verify build
if [ -f "netstat" ]; then
    log "Nettools built successfully"
    cp netstat "$BINARIES_DIR/netstat"
    cp arp "$BINARIES_DIR/arp"
    cp ifconfig "$BINARIES_DIR/ifconfig"
    cp iptunnel "$BINARIES_DIR/iptunnel"
    cp route "$BINARIES_DIR/route"
    log "Nettools binaries copied to $BINARIES_DIR"
else
    log "Nettools build failed"
    exit 1
fi

log "Nettools build process completed"
