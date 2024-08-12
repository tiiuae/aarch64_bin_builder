#!/bin/bash
set -euo pipefail

# Configuration
OPENSSL_VERSION="1.1.1q"
NMAP_REPO="https://github.com/nmap/nmap.git"
LOG_FILE="build_nmap.log"
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
    CC='/opt/cross/bin/aarch64-linux-musleabi-gcc -static' ./Configure no-shared linux-aarch64 no-tests

    # Build
    make -j"$(nproc)"
    log "Finished building static OpenSSL"
}

build_nmap() {
    cd /tmp

    # Clone Nmap repository
    if [ ! -d "nmap" ]; then
        log "Cloning Nmap repository"
        git clone --depth=1 "$NMAP_REPO"
        cd nmap
    else
        log "Nmap directory already exists, updating"
        cd nmap
        git pull
    fi

    CC='/opt/cross/bin/aarch64-linux-musleabi-gcc -static -fPIC' \
        CXX='/opt/cross/bin/aarch64-linux-musleabi-g++ -static -static-libstdc++ -fPIC' \
        LD=/opt/cross/bin/aarch64-linux-musleabi-ld \
        LDFLAGS="-L/tmp/openssl-${OPENSSL_VERSION} -s" \
        ./configure --without-ndiff --without-zenmap --without-nmap-update --with-pcap=linux --with-openssl=/tmp/openssl-${OPENSSL_VERSION} --host=aarch64-linux-musl

    # Don't build the libpcap.so file
    sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile
    sed -i -e 's/shared\: /shared\: #/' libz/Makefile

    # Build
    make -j"$(nproc)"
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting Nmap build process for aarch64 (static)"

build_openssl
build_nmap

# Verify build
if [ -f "nmap" ]; then
    log "Nmap built successfully"
    cp nmap "$BINARIES_DIR/nmap"
    cp ncat/ncat "$BINARIES_DIR/ncat"
    cp nping/nping "$BINARIES_DIR/nping"
    tar cvfz "$BINARIES_DIR/nmap_usrsharenmap.tar.gz" nselib/* scripts/* docs/nmap.dtd nmap-mac-prefixes nmap-os-db nmap-protocols nmap-rpc nmap-service-probes nmap-services docs/nmap.xsl nse_main.lua
    log "Nmap binaries copied to $BINARIES_DIR"
else
    log "Nmap build failed"
    exit 1
fi

log "Nmap build process completed"
