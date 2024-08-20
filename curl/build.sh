#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
CARES_VERSION="1.33.0"
CARES_URL="https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz"
WOLFSSL_VERSION="5.7.0"
WOLFSSL_URL="https://github.com/wolfSSL/wolfssl/archive/refs/tags/v${WOLFSSL_VERSION}-stable.zip"
CURL_VERSION="8.9.1"
CURL_URL="https://github.com/curl/curl/releases/download/curl-$(echo $CURL_VERSION | tr . _)/curl-${CURL_VERSION}.tar.xz"

build_cares() {
	log "Building c-ares dep..."
	. fetch_archive "$CARES_URL"

	CFLAGS="-static -fPIC" \
		./configure --host="$HOST" \
		--disable-shared \
		--enable-static \
		--prefix=/tmp/cares-install
	make LDFLAGS="-static -s" -j"$(nproc)"
	make install
}

build_wolfssl() {
	log "Building wolfSSL dep..."
	. fetch_archive "$WOLFSSL_URL"

	./autogen.sh
	CFLAGS="-static -fPIC" \
		./configure --host="$HOST" \
		--disable-shared \
		--enable-static \
		--prefix=/tmp/wolfssl-install \
		--enable-tls13 \
		--enable-curl
	make LDFLAGS="-static -s" -j"$(nproc)"
	make install
}

build_curl() {
	log "Building cURL"
	. fetch_archive "$CURL_URL"

	CFLAGS="-fPIC -static" \
		CXXFLAGS="-fPIC -static" \
		LDFLAGS="-L/tmp/wolfssl-install/lib -L/tmp/cares-install/lib -static" \
		CPPFLAGS="-I/tmp/wolfssl-install/include -I/tmp/cares-install/include" \
		PKG_CONFIG_PATH="/tmp/wolfssl-install/lib/pkgconfig:/tmp/cares-install/lib/pkgconfig" \
		LIBS="-ldl -lm -lrt -lpthread -static /tmp/wolfssl-install/lib/libwolfssl.a /tmp/cares-install/lib/libcares.a" \
		./configure --host="$HOST" \
		--disable-shared \
		--enable-static \
		--enable-ipv6 \
		--enable-verbose \
		--enable-proxy \
		--enable-ftp \
		--enable-file \
		--enable-dict \
		--enable-telnet \
		--enable-tftp \
		--enable-unix-sockets \
		--with-wolfssl=/tmp/wolfssl-install \
		--enable-ares=/tmp/cares-install \
		--enable-static-deps \
		--enable-mime \
		--enable-form \
		--enable-cookies \
		--disable-pop3 \
		--disable-imap \
		--disable-smtp \
		--disable-rtsp \
		--disable-versioned-symbols \
		--disable-ldap \
		--disable-gopher \
		--disable-smb \
		--disable-manual \
		--disable-ldap \
		--disable-netrc \
		--disable-sspi \
		--without-librtmp

	make LDFLAGS="-all-static -L/tmp/wolfssl-install/lib -L/tmp/cares-install/lib" \
		LIBS="-ldl -lm -lrt -lpthread -static /tmp/wolfssl-install/lib/libwolfssl.a /tmp/cares-install/lib/libcares.a" \
		-j"$(nproc)"
}

log "Starting cURL build process..."
build_cares
build_wolfssl
build_curl
verify_build -b curl -p src
