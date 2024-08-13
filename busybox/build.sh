#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
BUSYBOX_VERSION="1.36.1"
BUSYBOX_REPO="https://www.busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

log "Starting BusyBox build process..."
. fetch_archive $BUSYBOX_REPO

log "Building busybox"
CROSS_COMPILE=aarch64-linux-musleabi- LDFLAGS=--static make defconfig busybox
verify_build busybox
