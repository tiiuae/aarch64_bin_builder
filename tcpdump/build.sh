#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
TCPDUMP_VERSION=4.99.4
TCPDUMP_URL=https://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz
LIBPCAP_VERSION=1.10.4
LIBPCAP_URL=https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz
LIBNL_URL="git://git.openwrt.org/project/libnl-tiny.git"
OPENSSL_VERSION="1.1.1q"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
LIBCAP_NG_URL="https://github.com/stevegrubb/libcap-ng.git"

build_libnl() {
	. fetch_repo $LIBNL_URL
	mkdir build && cd build
	cmake ..
	make -j"$MAKE_JOBS"
	if [ ! -d "$STATIC_LIBS_PATH/lib" ]; then
		mkdir -p "$STATIC_LIBS_PATH/lib"
	fi

	cp libnl-tiny.a "$STATIC_LIBS_PATH/lib/"
}

build_libpcap() {
	. fetch_archive $LIBPCAP_URL

	LDFLAGS="-L$STATIC_LIBS_PATH/lib -static -s" \
		LIBS="-lnl-tiny" \
		./configure \
		--prefix="$STATIC_LIBS_PATH" \
		--disable-shared \
		--enable-ipv6 \
		--host="$HOST" \
		--with-pcap=linux
	make -j"$MAKE_JOBS"
	make install
}

build_openssl() {
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests --prefix="$STATIC_LIBS_PATH"
	make -j"$MAKE_JOBS"
	make install_sw
}

build_libcap_ng() {
	. fetch_repo $LIBCAP_NG_URL
	./autogen.sh
	./configure \
		--prefix="$STATIC_LIBS_PATH" \
		--disable-shared \
		--host="$HOST" || true
	make -j"$MAKE_JOBS"
	make install
}

build_tcpdump() {
	. fetch_archive $TCPDUMP_URL

	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -static -s" \
		LIBS="-lssl -lpcap -lcap-ng -lnl-tiny -lcrypto" \
		./configure --host="$HOST" \
		--with-cap-ng \
		--with-crypto="$STATIC_LIBS_PATH"

	make -j"$MAKE_JOBS"
}

log "Starting tcpdump build process..."
log "Building libnl-tiny dep..."
wrunf build_libnl
log "Building libcap-ng dep..."
wrunf build_libcap_ng
log "Building libpcap dep..."
wrunf build_libpcap
log "Building openSSL dep..."
wrunf build_openssl
log "Building tcpdump..."
wrunf build_tcpdump
verify_build tcpdump
