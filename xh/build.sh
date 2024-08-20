#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
XH_REPO="https://github.com/ducaale/xh.git"

build_xh() {
	log "Starting xh build process..."
	. fetch_repo $XH_REPO

	log "Building xh"
	# Set up environment variables for cross-compilation
	export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musleabi-gcc
	export CC_aarch64_unknown_linux_musl=aarch64-linux-musleabi-gcc
	export RUSTFLAGS="-C target-feature=+crt-static"

	# Build xh
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/xh
}

build_xh
verify_build -b xh -p "target/aarch64-unknown-linux-musl/release"
