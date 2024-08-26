#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
FD_REPO="https://github.com/sharkdp/fd.git"

build_fd() {
	. fetch_repo $FD_REPO

	cargo build --target "$RUST_TARGET" --release
	aarch64-linux-musleabi-strip "$RUST_REL/fd"
}

log "Building fd"
wrunf build_fd
verify_build -b fd -p "$RUST_REL"
