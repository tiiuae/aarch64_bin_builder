#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
FD_REPO="https://github.com/sharkdp/fd.git"

build_fd() {
	log "Starting fd build process..."
	. fetch_repo $FD_REPO

	log "Building fd"
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/fd
}

build_fd
verify_build -b fd -p "target/aarch64-unknown-linux-musl/release"
