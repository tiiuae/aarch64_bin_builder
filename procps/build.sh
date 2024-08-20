#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
NCURSES_VERSION="6.5"
NCURSES_URL="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
PROCPS_REPO="https://gitlab.com/procps-ng/procps.git"
EXPECTED_BINARIES="free hugetop pgrep vmstat watch sysctl slabtop pwdx pkill pmap pidwait pidof pgrep kill"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_libncurses() {
	log "Building libncurses-dev dep..."
	. fetch_archive $NCURSES_URL

	log "Building ncurses"
	CC=aarch64-linux-musleabi-gcc \
		CXX=aarch64-linux-musleabi-g++ \
		LDFLAGS="-s -static" CFLAGS=-static \
		./configure --prefix="$STATIC_LIBS_PATH" \
		--host=aarch64-linux-musleabi \
		--without-ada \
		--without-cxx \
		--without-cxx-binding \
		--without-manpages \
		--without-progs \
		--disable-tic-depends \
		--without-tests \
		--disable-stripping \
		--with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" \
		--disable-db-install \
		--enable-widec
	make -j"$(nproc)"
	make install || true
}

build_procps() {
	log "Building procps"
	. fetch_repo $PROCPS_REPO

	./autogen.sh
	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I/tmp/static_libs/include" \
		CPPFLAGS="-I/tmp/static_libs/include" \
		LDFLAGS="-static -s -L/tmp/static_libs/lib" \
		LIBS="-static" \
		NCURSES_CFLAGS="-I/tmp/static_libs/include/ncursesw" \
		NCURSES_LIBS="-L/tmp/static_libs/lib -lncursesw" \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		./configure \
		--enable-static \
		--disable-shared \
		--host=aarch64-linux-musleabi \
		--with-ncurses \
		--disable-nls

	make LDFLAGS="-all-static -s" -j"$(nproc)"
}

build_libncurses
build_procps
verify_build -p src -b "$EXPECTED_BINARIES"
verify_build -p src/ps -b pscommand
verify_build -p src/top -b top
