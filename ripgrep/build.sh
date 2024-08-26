#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
RIPGREP_REPO="https://github.com/BurntSushi/ripgrep.git"

build_ripgrep() {
	. fetch_repo $RIPGREP_REPO

	cargo build --target "$RUST_TARGET" --release --features 'pcre2'
	aarch64-linux-musleabi-strip "$RUST_REL/rg"
}

log "Building ripgrep"
wrunf build_ripgrep
verify_build -b rg -p "$RUST_REL"
