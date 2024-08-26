#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
BUSYBOX_VERSION="1.36.1"
BUSYBOX_REPO="https://www.busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

build_busybox() {
	. fetch_archive $BUSYBOX_REPO

	unset CC
	CROSS_COMPILE=aarch64-linux-musleabi- LDFLAGS="--static -s" make defconfig busybox

}

log "Building busybox"
wrunf build_busybox
verify_build busybox
