#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
SOCAT_REPO="https://repo.or.cz/socat.git"
OPENSSL_VERSION="1.1.1q"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
READLINE_VERSION="master"
READLINE_REPO="http://git.savannah.gnu.org/cgit/readline.git/snapshot/readline-${READLINE_VERSION}.tar.gz"
TCP_WRAPPERS_REPO="https://github.com/pexip/os-tcp-wrappers.git"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_readline() {
	log "Building readline dep..."
	. fetch_archive $READLINE_REPO

	./configure --prefix=$STATIC_LIBS_PATH \
		--disable-shared \
		--enable-static \
		--host="$HOST"
	make -j"$(nproc)"
	make install
	log "Finished building static readline"
}

build_tcpwrappers() {
	log "Building tcp-wrappers dep..."
	. fetch_repo $TCP_WRAPPERS_REPO
	cp /build/tcp_wrapper_percent_m.patch percent_m.c
	make REAL_DAEMON_DIR=/usr/sbin STYLE=-DPROCESS_OPTIONS linux
	cp libwrap.a $STATIC_LIBS_PATH/lib
	log "Finished building static tcpwrappers"
}

build_openssl() {
	log "Building openSSL dep..."
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix=$STATIC_LIBS_PATH
	make -j"$(nproc)"
	make install_sw
	log "Finished building static OpenSSL"
}

build_socat() {
	log "Starting Socat build process..."
	. fetch_repo $SOCAT_REPO

	log "Building Socat"
	#NOTE: This is a workaround to fix an autoreconf error
	autoreconf -fi || true
	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -static -s" \
		LIBS="-lwrap -lreadline" \
		./configure --host="$HOST"

	LDFLAGS="--static" make -j"$(nproc)"
}

build_readline
build_tcpwrappers
build_openssl
build_socat
verify_build socat
