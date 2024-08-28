#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
VIM_VERSION="9.1.0686"
VIM_URL="https://github.com/vim/vim/archive/refs/tags/v${VIM_VERSION}.tar.gz"
NCURSES_VERSION="6.5"
NCURSES_URL="https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"

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
	make install || true
}

build_vim() {
	. fetch_archive $VIM_URL

	CFLAGS="-static -I$STATIC_LIBS_PATH/include" \
		CPPFLAGS="-I$STATIC_LIBS_PATH/include" \
		LDFLAGS="-static -s -L$STATIC_LIBS_PATH/lib" \
		LIBS="-static -lncursesw" \
		vim_cv_toupper_broken=no \
		vim_cv_terminfo=yes \
		vim_cv_tgetent=zero \
		vim_cv_getcwd_broken=no \
		vim_cv_timer_create_with_lrt=no \
		vim_cv_timer_create=no \
		vim_cv_stat_ignores_slash=yes \
		vim_cv_memmove_handles_overlap=yes \
		./configure --disable-channel \
		--host="$HOST" \
		--disable-gpm \
		--disable-gtktest \
		--disable-gui \
		--disable-netbeans \
		--disable-nls \
		--disable-selinux \
		--disable-smack \
		--disable-sysmouse \
		--disable-xsmp \
		--enable-multibyte \
		--with-features=huge \
		--without-x \
		--with-tlib=ncursesw

	make -j"$(/bin/get_cores)"
}

log "Starting vim build process..."
log "Building libncurses-dev dep..."
wrunf build_libncurses
log "Building vim"
wrunf build_vim
verify_build -b vim -p src
