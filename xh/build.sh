#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
XH_REPO="https://github.com/ducaale/xh.git"

build_xh() {
	log "Starting xh build process..."
	. fetch_repo $XH_REPO

	log "Building xh"
	unset CC
	unset CXX
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/xh
}

build_xh
verify_build -b xh -p "target/aarch64-unknown-linux-musl/release"
