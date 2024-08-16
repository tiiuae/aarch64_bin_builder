#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
export WEBSOCAT_REPO="https://github.com/vi/websocat.git"
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_openssl() {
	log "Building openSSL dep..."
	. fetch_archive $OPENSSL_URL
	CC='/opt/cross/bin/aarch64-linux-musleabi-gcc -static' \
		./Configure no-shared linux-aarch64 no-tests --prefix=$STATIC_LIBS_PATH
	make -j"$(nproc)"
	make install_sw
	log "Finished building static OpenSSL"
}

build_websocat() {
	log "Starting Websocat build process..."
	. fetch_repo $WEBSOCAT_REPO

	log "Building Websocat"
	# Set up environment variables for cross-compilation
	export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=aarch64-linux-musleabi-gcc
	export CC_aarch64_unknown_linux_musl=aarch64-linux-musleabi-gcc
	export RUSTFLAGS="-C target-feature=+crt-static"

	# Point to our custom-built OpenSSL
	export OPENSSL_DIR=$STATIC_LIBS_PATH
	export OPENSSL_STATIC=1
	export PKG_CONFIG_ALLOW_CROSS=1

	# Build websocat
	. "$HOME/.cargo/env"
	cargo build --target aarch64-unknown-linux-musl --release --features=ssl
	aarch64-linux-musleabi-strip target/aarch64-unknown-linux-musl/release/websocat
}

build_openssl
build_websocat
verify_build -b websocat -p "target/aarch64-unknown-linux-musl/release"
