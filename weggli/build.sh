#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
WEGGLI_REPO="https://github.com/weggli-rs/weggli.git"

build_weggli() {
	. fetch_repo $WEGGLI_REPO

	cargo build --target "$RUST_TARGET" --release
	aarch64-linux-musleabi-strip "$RUST_REL/weggli"
}

log "Building weggli"
wrunf build_weggli
verify_build -b weggli -p "$RUST_REL/weggli"
