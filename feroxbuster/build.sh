#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
FEROXBUSTER_REPO="https://github.com/epi052/feroxbuster.git"

build_feroxbuster() {
	. fetch_repo $FEROXBUSTER_REPO

	cargo build --target "$RUST_TARGET" --release
	aarch64-linux-musleabi-strip "$RUST_REL/feroxbuster"
}

log "Building feroxbuster"
wrunf build_feroxbuster
verify_build -b feroxbuster -p "$RUST_REL"
