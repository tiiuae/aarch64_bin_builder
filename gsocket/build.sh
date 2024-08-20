#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
export GSOCKET_REPO="https://github.com/hackerschoice/gsocket.git"
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

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

build_gsocket() {
	log "Building gsocket..."
	. fetch_repo $GSOCKET_REPO
	./bootstrap

	CFLAGS="-I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -s -fPIC" \
		./configure --host="$HOST" --enable-static
	make all -j"$(nproc)"

}

build_openssl
build_gsocket
verify_build -b gs-netcat -p tools
#NOTE: Manual tar archive of all the things including bash scripts and shared libraries
cd tools && tar cfz "$BINARIES_DIR/gsocket.tar.gz" gs-netcat gsocket blitz gs-mount gs-sftp gs_funcs gsocket_dso.so.0 gsocket_uchroot_dso.so.0
