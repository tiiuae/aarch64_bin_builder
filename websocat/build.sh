#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
WEBSOCAT_REPO="https://github.com/vi/websocat.git"
OPENSSL_VERSION="1.1.1q"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

build_openssl() {
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix="$STATIC_LIBS_PATH"
	make -j"$MAKE_JOBS"
	make install_sw
}

build_websocat() {
	. fetch_repo $WEBSOCAT_REPO

	# Point to our custom-built OpenSSL
	export OPENSSL_DIR=$STATIC_LIBS_PATH
	export OPENSSL_STATIC=1
	export PKG_CONFIG_ALLOW_CROSS=1

	cargo build --target "$RUST_TARGET" --release --features=ssl
	aarch64-linux-musleabi-strip "$RUST_REL/websocat"
}

log "Starting websocat build process..."
log "Building openSSL dep..."
wrunf build_openssl
log "Building websocat"
wrunf build_websocat
verify_build -b websocat -p "$RUST_REL"
