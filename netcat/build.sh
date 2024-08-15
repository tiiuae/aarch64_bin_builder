#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
NETCAT_URL="https://sourceforge.net/projects/netcat/files/latest/download"

log "Starting Netcat build process..."
. fetch_archive $NETCAT_URL

log "Building Netcat"
wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
chmod +x config.sub
./configure --host=aarch64-linux-musleabi CC=aarch64-linux-musleabi-gcc CXX=aarch64-linux-musleabi-g++ LDFLAGS="-s -static" CFLAGS=-static
make -j"$(nproc)"
verify_build -b netcat -p src