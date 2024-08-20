#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
FD_REPO="https://github.com/sharkdp/fd.git"

build_fd() {
	log "Starting fd build process..."
	. fetch_repo $FD_REPO

	log "Building fd"
	# Set up environment variables for cross-compilation
	export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musleabi-gcc
	export RUSTFLAGS="-C target-feature=+crt-static"

	# Build fd
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/fd
}

build_fd
verify_build -b fd -p "target/aarch64-unknown-linux-musl/release"
