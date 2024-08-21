#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
export RSYNC_REPO="https://github.com/RsyncProject/rsync.git"
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export XXHASH_REPO="https://github.com/Cyan4973/xxHash.git"
export ZSTD_VERSION="1.5.6"
export ZSTD_URL="https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz"
export LZ4_VERSION="1.10.0"
export LZ4_URL="https://github.com/lz4/lz4/releases/download/v${LZ4_VERSION}/lz4-${LZ4_VERSION}.tar.gz"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_openssl() {
	log "Building openSSL dep..."
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix=$STATIC_LIBS_PATH
	make -j"$(nproc)"
	make install_sw
	log "Finished building static OpenSSL"
}

build_xxhash() {
	log "Building xxhash..."
	. fetch_repo $XXHASH_REPO

	make prefix=$STATIC_LIBS_PATH install -j"$(nproc)"
	log "Finished building static xxhash"
}

build_zstd() {
	log "Building zstd dep..."
	. fetch_archive $ZSTD_URL

	make prefix=$STATIC_LIBS_PATH install -j"$(nproc)"
	log "Finished building static zstd"
}

build_lz4() {
	log "Building lz4 dep..."
	. fetch_archive $LZ4_URL

	make prefix=$STATIC_LIBS_PATH install -j"$(nproc)"
	log "Finished building static lz4"
}

build_rsync() {
	log "Building tcpdump..."
	. fetch_repo $RSYNC_REPO

	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LIBS="-L$STATIC_LIBS_PATH/lib" \
		./configure --host="$HOST" \
		--disable-md2man

	make -j"$(nproc)"
}

build_openssl
build_zstd
build_xxhash
build_lz4
build_rsync
verify_build rsync
