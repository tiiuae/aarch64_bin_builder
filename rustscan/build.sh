#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
RUSTSCAN_REPO="https://github.com/RustScan/RustScan.git"

build_rustscan() {
	log "Starting rustscan build process..."
	. fetch_repo $RUSTSCAN_REPO

	log "Building rustscan"
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/rustscan
}

build_rustscan
verify_build -b rustscan -p "target/aarch64-unknown-linux-musl/release"
