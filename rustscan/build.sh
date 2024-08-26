#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
RUSTSCAN_REPO="https://github.com/RustScan/RustScan.git"

build_rustscan() {
	. fetch_repo $RUSTSCAN_REPO

	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip "$RUST_REL/rustscan"
}

log "Building rustscan"
wrunf build_rustscan
verify_build -b rustscan -p "$RUST_REL"
