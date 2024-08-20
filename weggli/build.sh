#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
WEGGLI_REPO="https://github.com/weggli-rs/weggli.git"

build_weggli() {
	log "Starting weggli build process..."
	. fetch_repo $WEGGLI_REPO

	log "Building weggli"
	cargo build --target aarch64-unknown-linux-musl --release
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/weggli
}

build_weggli
verify_build -b weggli -p "target/aarch64-unknown-linux-musl/release"
