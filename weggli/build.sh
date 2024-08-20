#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
WEGGLI_REPO="https://github.com/weggli-rs/weggli.git"

build_weggli() {
	log "Starting weggli build process..."
	. fetch_repo $WEGGLI_REPO

	log "Building weggli"
	# Set up environment variables for cross-compilation
	export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musleabi-gcc
	export CC_aarch64_unknown_linux_musl=aarch64-linux-musleabi-gcc
	export RUSTFLAGS="-C target-feature=+crt-static"

	# Build weggli
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/weggli
}

build_weggli
verify_build -b weggli -p "target/aarch64-unknown-linux-musl/release"
