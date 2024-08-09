#!/bin/bash
set -euo pipefail

# Configuration
LOG_FILE="build_curl.log"
BINARIES_DIR="/repo/binaries"
CARES_VERSION="1.33.0"
CARES_URL=" https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz"
WOLFSSL_VERSION="5.7.0"
WOLFSSL_URL="https://github.com/wolfSSL/wolfssl/archive/refs/tags/v${WOLFSSL_VERSION}-stable.zip"
CURL_VERSION="8.9.1"
CURL_URL="https://github.com/curl/curl/releases/download/curl-$(echo $CURL_VERSION | tr . _)/curl-${CURL_VERSION}.tar.xz"

# Function for logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function for error handling
handle_error() {
    log "Error occurred on line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting cURL build process for aarch64 (static)"

build_cares() {
    cd /tmp
    if [ ! -d "c-ares-${CARES_VERSION}" ]; then
        log "Fetching c-ares code"
        wget -qO- $CARES_URL | tar xvz
        cd c-ares-${CARES_VERSION}
    fi

    CC="aarch64-linux-musleabi-gcc -static" \
        CXX="aarch64-linux-musleabi-g++ -static" \
        CFLAGS="-static -fPIC" \
        ./configure --host=aarch64-linux-musleabi \
        --disable-shared \
        --enable-static \
        --prefix=/tmp/cares-install
    make LDFLAGS="-static -s" -j"$(nproc)"
    make install
}

build_wolfssl() {
    cd /tmp
    if [ ! -d "wolfssl-${WOLFSSL_VERSION}-stable" ]; then
        log "Fetching wolfssl code"
        wget -q $WOLFSSL_URL
        unzip v${WOLFSSL_VERSION}-stable.zip
        cd wolfssl-${WOLFSSL_VERSION}-stable
    fi

    ./autogen.sh
    CC="aarch64-linux-musleabi-gcc -static" \
        CXX="aarch64-linux-musleabi-g++ -static" \
        CFLAGS="-static -fPIC" \
        ./configure --host=aarch64-linux-musleabi \
        --disable-shared \
        --enable-static \
        --prefix=/tmp/wolfssl-install \
        --enable-tls13 \
        --enable-curl
    make LDFLAGS="-static -s" -j"$(nproc)"
    make install
}

build_curl() {
    cd /tmp
    if [ ! -d "curl-${CURL_VERSION}" ]; then
        log "Fetching cURL code"
        wget -qO- $CURL_URL | tar xJ
        cd curl-${CURL_VERSION}
    fi

    CC="aarch64-linux-musleabi-gcc" \
        CXX="aarch64-linux-musleabi-g++" \
        CFLAGS="-fPIC -static" \
        CXXFLAGS="-fPIC -static" \
        LDFLAGS="-L/tmp/wolfssl-install/lib -L/tmp/cares-install/lib -static" \
        CPPFLAGS="-I/tmp/wolfssl-install/include -I/tmp/cares-install/include" \
        PKG_CONFIG_PATH="/tmp/wolfssl-install/lib/pkgconfig:/tmp/cares-install/lib/pkgconfig" \
        LIBS="-ldl -lm -lrt -lpthread -static /tmp/wolfssl-install/lib/libwolfssl.a /tmp/cares-install/lib/libcares.a" \
        ./configure --host=aarch64-linux-musleabi \
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

build_cares
build_wolfssl
build_curl

# Verify build
if [ -f "src/curl" ]; then
    log "cURL built successfully"
    cp src/curl "$BINARIES_DIR/curl"
    log "cURL binary copied to $BINARIES_DIR/curl"
else
    log "cURL build failed"
    exit 1
fi
