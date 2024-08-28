#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
NCURSES_VERSION="6.5"
NCURSES_URL="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
LIBEVENT_REPO="https://github.com/libevent/libevent.git"
TMUX_REPO="https://github.com/tmux/tmux.git"

build_libevent() {
	. fetch_repo $LIBEVENT_REPO

	./autogen.sh
	./configure --prefix="$STATIC_LIBS_PATH" \
		--host="$HOST"

	make -j"$(/bin/get_cores)"
	make install
}

build_libncurses() {
	. fetch_archive $NCURSES_URL

	./configure --prefix="$STATIC_LIBS_PATH" \
		--host="$HOST" \
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
	make -j"$(/bin/get_cores)"
	make install
}

build_tmux() {
	. fetch_repo $TMUX_REPO

	./autogen.sh
	CFLAGS="-static -s -I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-static -s -L$STATIC_LIBS_PATH/lib" \
		LIBNCURSES_CFLAGS="-I$STATIC_LIBS_PATH/include/ncursesw" \
		LIBNCURSES_LIBS="-L$STATIC_LIBS_PATH/lib -lncursesw" \
		./configure \
		--enable-static \
		--host="$HOST"

	make -j"$(/bin/get_cores)"
}

log "Starting tmux build process..."
log "Building libevent dep..."
wrunf build_libevent
log "Building libncurses-dev dep..."
wrunf build_libncurses
log "Building tmux"
wrunf build_tmux
verify_build tmux
