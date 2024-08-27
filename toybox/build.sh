#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
TOYBOX_REPO="https://github.com/landley/toybox.git"

build_toybox() {
	. fetch_repo $TOYBOX_REPO

	NOSTRIP="y" make LDFLAGS="--static -s" defconfig toybox
}

log "Building Toybox"
wrunf build_toybox
verify_build toybox
