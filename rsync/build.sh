#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
RSYNC_REPO="https://github.com/RsyncProject/rsync.git"
OPENSSL_VERSION="1.1.1q"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
XXHASH_REPO="https://github.com/Cyan4973/xxHash.git"
ZSTD_VERSION="1.5.6"
ZSTD_URL="https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz"
LZ4_VERSION="1.10.0"
LZ4_URL="https://github.com/lz4/lz4/releases/download/v${LZ4_VERSION}/lz4-${LZ4_VERSION}.tar.gz"

build_openssl() {
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix="$STATIC_LIBS_PATH"
	make -j"$MAKE_JOBS"
	make install_sw
}

build_xxhash() {
	. fetch_repo $XXHASH_REPO

	make prefix="$STATIC_LIBS_PATH" install -j"$MAKE_JOBS"
}

build_zstd() {
	. fetch_archive $ZSTD_URL

	make prefix="$STATIC_LIBS_PATH" install -j"$MAKE_JOBS"
}

build_lz4() {
	. fetch_archive $LZ4_URL

	make prefix="$STATIC_LIBS_PATH" install -j"$MAKE_JOBS"
}

build_rsync() {
	. fetch_repo $RSYNC_REPO

	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LIBS="-L$STATIC_LIBS_PATH/lib" \
		./configure --host="$HOST" \
		--disable-md2man

	make -j"$MAKE_JOBS"
}

log "Starting rsync build process..."
log "Building openSSL dep..."
wrunf build_openssl
log "Building zstd dep..."
wrunf build_zstd
log "Building xxhash dep..."
wrunf build_xxhash
log "Building lz4 dep..."
wrunf build_lz4
log "Building rsync"
wrunf build_rsync
verify_build rsync
