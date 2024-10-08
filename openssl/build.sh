#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
OPENSSL_VERSION="3.3.1"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

build_openssl() {
	. fetch_archive $OPENSSL_URL
	unset CC
	unset CXX
	./Configure no-shared \
		linux-aarch64 \
		no-tests \
		--cross-compile-prefix=/opt/cross/bin/aarch64-linux-musleabi-
	make -j"$(/bin/get_cores)"
}

log "Building openSSL"
wrunf build_openssl
verify_build -b "openssl" -p "apps"
