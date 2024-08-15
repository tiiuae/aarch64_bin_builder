#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
TAR_VERSION="1.35"
TAR_REPO="https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.xz"

log "Starting Tar build process..."
. fetch_archive $TAR_REPO

log "Building Tar"
CC=/opt/cross/bin/aarch64-linux-musleabi-gcc \
	CFLAGS=-static \
	LDFLAGS="-static -s" \
	./configure --host=aarch64-linux-musleabi
make -j"$(nproc)"
verify_build -b "tar" -p "src"
