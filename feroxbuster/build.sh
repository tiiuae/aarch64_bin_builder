#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
FEROXBUSTER_REPO="https://github.com/epi052/feroxbuster.git"

build_feroxbuster() {
	log "Starting feroxbuster build process..."
	. fetch_repo $FEROXBUSTER_REPO

	log "Building feroxbuster"
	# Set up environment variables for cross-compilation
	export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musleabi-gcc
	export CC_aarch64_unknown_linux_musl=aarch64-linux-musleabi-gcc
	export RUSTFLAGS="-C target-feature=+crt-static"

	# Build feroxbuster
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/feroxbuster
}

build_feroxbuster
verify_build -b feroxbuster -p "target/aarch64-unknown-linux-musl/release"
