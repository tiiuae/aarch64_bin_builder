#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
XH_REPO="https://github.com/ducaale/xh.git"

build_xh() {
	. fetch_repo $XH_REPO

	unset CC
	unset CXX
	cargo build --target "$RUST_TARGET" --release
	aarch64-linux-musleabi-strip "$RUST_REL/xh"
}

log "Building xh"
wrunf build_xh
verify_build -b xh -p "$RUST_REL"
