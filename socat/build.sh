#!/bin/bash
set -euo pipefail

# Configuration
SOCAT_REPO="https://repo.or.cz/socat.git"
OPENSSL_VERSION="1.1.1q"
READLINE_REPO="http://git.savannah.gnu.org/cgit/readline.git/snapshot/readline-master.tar.gz"
TCP_WRAPPERS_REPO="https://github.com/pexip/os-tcp-wrappers.git"
LOG_FILE="build_socat.log"
BINARIES_DIR="/repo/binaries"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

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

build_readline() {
    cd /tmp

    curl -LOk $READLINE_REPO
    tar zxvf readline-master.tar.gz
    cd readline-master

    CC='aarch64-linux-musleabi-gcc -static' \
        CFLAGS="-static" \
        ./configure --prefix=$STATIC_LIBS_PATH --disable-shared --enable-static --host=aarch64-linux-musleabi

    # Build
    make -j"$(nproc)"
    make install
    log "Finished building static readline"

}

build_tcpwrappers() {
    cd /tmp

    git clone --depth=1 $TCP_WRAPPERS_REPO
    cd os-tcp-wrappers
    mv /build/tcp_wrapper_percent_m.patch percent_m.c
    CC='aarch64-linux-musleabi-gcc' \
        CFLAGS="-static" \
        LDFLAGS="-static" \
        make REAL_DAEMON_DIR=/usr/sbin STYLE=-DPROCESS_OPTIONS linux
    cp libwrap.a $STATIC_LIBS_PATH/lib
    log "Finished building static tcpwrappers"
}

build_openssl() {
    cd /tmp

    # Download
    curl -LOk https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar zxvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}

    # Configure
    CC='/opt/cross/bin/aarch64-linux-musleabi-gcc -static' \
        ./Configure no-shared linux-aarch64 no-tests --prefix=$STATIC_LIBS_PATH

    # Build
    make -j"$(nproc)"
    make install
    log "Finished building static OpenSSL"
}

build_socat() {
    cd /tmp

    # Build socat
    log "Starting socat build process for aarch64 (static)"

    # Clone socat repository
    if [ ! -d "socat" ]; then
        log "Cloning socat repository"
        git clone --depth=1 "$SOCAT_REPO"
        cd socat
    else
        log "socat directory already exists, updating"
        cd socat
        git pull
    fi
    autoreconf -fi || true

    CC="aarch64-linux-musleabi-gcc" \
        CXX="aarch64-linux-musleabi-g++" \
        CFLAGS="-static" \
        CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
        LDFLAGS="-L$STATIC_LIBS_PATH/lib -static -s" \
        LIBS="-lwrap -lreadline" \
        ./configure --host=aarch64-linux-musleabi

    LDFLAGS="--static" make -j"$(nproc)"

    echo "Static socat binary compiled successfully."
}

build_readline
build_tcpwrappers
build_openssl
build_socat

# Verify build
if [ -f "socat" ]; then
    log "socat built successfully"
    cp socat "$BINARIES_DIR/socat"
    log "socat binary copied to $BINARIES_DIR/socat"
else
    log "socat build failed"
    exit 1
fi

log "socat build process completed"
