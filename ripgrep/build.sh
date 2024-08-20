#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
RIPGREP_REPO="https://github.com/BurntSushi/ripgrep.git"

build_ripgrep() {
	log "Starting ripgrep build process..."
	. fetch_repo $RIPGREP_REPO

	log "Building ripgrep"
	cargo build --target aarch64-unknown-linux-musl --release --features 'pcre2'
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/rg
}

build_ripgrep
verify_build -b rg -p "target/aarch64-unknown-linux-musl/release"
