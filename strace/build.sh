#!/bin/bash
set -euo pipefail

# Configuration
export STRACE_REPO="https://github.com/strace/strace.git"
export LIBUNWIND_VERSION="1.8.1"
export LIBUNWIND_URL="https://github.com/libunwind/libunwind/releases/download/v${LIBUNWIND_VERSION}/libunwind-${LIBUNWIND_VERSION}.tar.gz"
export LIBXZ_VERSION="5.6.2"
export LIBXZ_URL="https://github.com/tukaani-project/xz/releases/download/v${LIBXZ_VERSION}/xz-${LIBXZ_VERSION}.tar.gz"
export ZLIB_VERSION="1.3.1"
export ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_libxz() {
	log "Building xz dep..."
	. fetch_archive $LIBXZ_URL

	./configure \
		--host="$HOST" \
		--prefix="$STATIC_LIBS_PATH" \
		--disable-nls \
		--disable-shared \
		--enable-static \
		--disable-doc \
		--disable-scripts \
		--disable-doxygen \
		--enable-debug-frame \
		--enable-threads=posix \
		--enable-small

	make -j"$(nproc)"
	make install
	log "Finished building static xz"
}

build_zlib() {
	log "Building zlib dep..."
	. fetch_archive $ZLIB_URL

	./configure \
		--prefix="$STATIC_LIBS_PATH" \
		--static

	make -j"$(nproc)"
	make install
	log "Finished building static zlib"
}

build_libunwind() {
	log "Building libunwind dep..."
	. fetch_archive $LIBUNWIND_URL

	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib" \
		LIBS="-llzma" \
		./configure \
		--host="$HOST" \
		--prefix="$STATIC_LIBS_PATH" \
		--enable-static \
		--disable-tests \
		--disable-documentation \
		--enable-debug-frame \
		--enable-minidebuginfo \
		--enable-zlibdebuginfo

	#NOTE: There's a build error related to redefine of multiple structs...
	sed -i 's/#include <asm\/sigcontext.h>/\/\/#include <asm\/sigcontext.h>/g' /opt/cross/aarch64-linux-musleabi/include/asm/ptrace.h

	make -j"$(nproc)"
	make install

	log "Finished building static libunwind"
}

build_strace() {
	. fetch_repo $STRACE_REPO

	./boostrap
	#FIXME: There's an issue with libunwind and m32 personality support
	CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib" \
		LIBS="-L$STATIC_LIBS_PATH/lib -lunwind-aarch64 -llzma" \
		./configure \
		--host="$HOST" \
		--enable-arm-oabi \
		--with-libunwind \
		--with-libiberty \
		--enable-mpers=m32 \
		--with-gcov=no \
		--with-libselinux=no || true

	make -j"$(nproc)"
}

build_libxz
build_zlib
build_libunwind
#build_strace
