#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
export GSOCKET_REPO="https://github.com/hackerschoice/gsocket.git"
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"

build_openssl() {
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix="$STATIC_LIBS_PATH"
	make -j"$MAKE_JOBS"
	make install_sw
}

build_gsocket() {
	. fetch_repo $GSOCKET_REPO
	./bootstrap

	CFLAGS="-I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -s -fPIC" \
		./configure --host="$HOST" --enable-static
	make all -j"$MAKE_JOBS"

}

log "Starting gsocket build process..."
log "Build openSSL dep..."
wrunf build_openssl
log "Building gsocket"
wrunf build_gsocket
verify_build -b gs-netcat -p tools
#NOTE: Manual tar archive of all the things including bash scripts and shared libraries
cd tools && tar cfz "$BINARIES_DIR/gsocket.tar.gz" gs-netcat gsocket blitz gs-mount gs-sftp gs_funcs gsocket_dso.so.0 gsocket_uchroot_dso.so.0
