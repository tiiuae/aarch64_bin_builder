#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
export WIRESHARK_REPO="https://gitlab.com/wireshark/wireshark.git"
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export LIBNL_URL="git://git.openwrt.org/project/libnl-tiny.git"
export LIBPCAP_VERSION=1.10.4
export LIBPCAP_URL=https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz
export LIBCAP_NG_URL="https://github.com/stevegrubb/libcap-ng.git"
export ZLIB_VERSON="1.3.1"
export ZLIB_URL="https://zlib.net/zlib-${ZLIB_VERSON}.tar.gz"
export BROTLI_REPO="https://github.com/google/brotli.git"
export GLIB_REPO="https://gitlab.gnome.org/GNOME/glib.git"
export LIBGPG_ERROR_REPO="https://github.com/gpg/libgpg-error.git"
export LIBGCRYPT_REPO="https://github.com/gpg/libgcrypt.git"
export CARES_VERSION="1.33.0"
export CARES_URL="https://github.com/c-ares/c-ares/releases/download/v${CARES_VERSION}/c-ares-${CARES_VERSION}.tar.gz"
export SPEEXDSP_REPO="https://github.com/xiph/speexdsp.git"
export LIBUSB_REPO="https://github.com/libusb/libusb.git"

mkdir -p /tmp/static_libs
STATIC_LIBS_PATH=/tmp/static_libs

build_libnl() {
	log "Building libnl-tiny dep..."
	. fetch_repo $LIBNL_URL
	mkdir build && cd build
	CC='aarch64-linux-musleabi-gcc' CFLAGS='-static -fPIC' LDFLAGS=-static cmake ..
	make -j"$(nproc)"
	if [ ! -d "$STATIC_LIBS_PATH/lib" ]; then
		mkdir -p $STATIC_LIBS_PATH/lib
	fi

	cp libnl-tiny.a $STATIC_LIBS_PATH/lib/
}

build_libpcap() {
	log "Building libpcap dep..."
	. fetch_archive $LIBPCAP_URL

	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -fPIC" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -static -s" \
		LIBS="-lnl-tiny" \
		./configure \
		--prefix=$STATIC_LIBS_PATH \
		--disable-shared \
		--enable-ipv6 \
		--host=aarch64-linux-musleabi \
		--with-pcap=linux
	make -j"$(nproc)"
	make install
}

build_openssl() {
	log "Building openSSL dep..."
	. fetch_archive $OPENSSL_URL
	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS='-static -fPIC' \
		./Configure no-shared linux-aarch64 no-tests --prefix=$STATIC_LIBS_PATH
	make -j"$(nproc)"
	make install_sw
	log "Finished building static OpenSSL"
}

build_zlib() {
	log "Building zlib dep..."
	. fetch_archive $ZLIB_URL
	CC='aarch64-linux-musleabi-gcc -static' \
		CFLAGS="-static -fPIC" \
		LDFLAGS="-static -s" \
		./configure \
		--prefix=$STATIC_LIBS_PATH \
		--static
	make -j"$(nproc)"
	make install
}

build_brotli() {
	log "Building brotli dep..."
	. fetch_repo $BROTLI_REPO
	mkdir build && cd build

	CC='aarch64-linux-musleabi-gcc -static -fPIC' \
		CFLAGS="-static" \
		LDFLAGS="-static -s" \
		cmake -DCMAKE_INSTALL_PREFIX=$STATIC_LIBS_PATH \
		-DBUILD_SHARED_LIBS=OFF \
		-DBROTLI_DISABLE_TESTS=ON \
		..

	CC='aarch64-linux-musleabi-gcc -static -fPIC' \
		CFLAGS="-static" \
		LDFLAGS="-static -s" \
		make -j"$(nproc)"

	make install
}

build_glib() {
	log "Building glib dep..."
	. fetch_repo $GLIB_REPO
	local repo
	repo=$(pwd)

	# Create a separate build directory
	BUILD_DIR="/tmp/glib_build"
	mkdir -p $BUILD_DIR
	cd $BUILD_DIR

	# Ensure we have pkg-config available
	export PKG_CONFIG_PATH="$STATIC_LIBS_PATH/lib/pkgconfig"

	# Create a cross-file for meson
	cat >aarch64-linux-musl-cross.txt <<EOF
[binaries]
c = 'aarch64-linux-musleabi-gcc'
cpp = 'aarch64-linux-musleabi-g++'
ar = 'aarch64-linux-musleabi-ar'
strip = 'aarch64-linux-musleabi-strip'
pkgconfig = 'pkg-config'

[host_machine]
system = 'linux'
cpu_family = 'aarch64'
cpu = 'aarch64'
endian = 'little'

[properties]
c_args = ['-static', '-fPIC']
c_link_args = ['-static', '-fPIC']
cpp_args = ['-static', '-fPIC']
cpp_link_args = ['-static', '-fPIC']
EOF

	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-static -L$STATIC_LIBS_PATH/lib" \
		meson setup "$repo" \
		--prefix=$STATIC_LIBS_PATH \
		--cross-file aarch64-linux-musl-cross.txt \
		--default-library=static \
		--buildtype=release \
		-Dforce_posix_threads=true \
		-Dxattr=false \
		-Dselinux=disabled \
		-Dlibmount=disabled \
		-Dnls=disabled \
		-Dtests=false \
		-Dintrospection=disabled \
		-Ddtrace=disabled \
		-Dsystemtap=disabled \
		-Dman=false \
		-Ddocumentation=false \
		-Dglib_assert=false \
		-Doss_fuzz=disabled \
		-Dglib_checks=false

	# Build
	ninja -j"$(nproc)"
	ninja install
}

build_gpg_error() {
	log "Building libgpg-error dep..."
	. fetch_repo "$LIBGPG_ERROR_REPO"

	./autogen.sh

	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-static -L$STATIC_LIBS_PATH/lib" \
		./configure \
		--host=aarch64-linux-musleabi \
		--prefix=$STATIC_LIBS_PATH \
		--enable-static \
		--disable-shared \
		--disable-nls \
		--disable-doc

	make -j"$(nproc)"
	make install
}

build_gcrypt() {
	log "Building libgcrypt dep..."
	. fetch_repo "$LIBGCRYPT_REPO"

	./autogen.sh
	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-static -L$STATIC_LIBS_PATH/lib" \
		./configure \
		--host=aarch64-linux-musleabi \
		--prefix=$STATIC_LIBS_PATH \
		--enable-static \
		--disable-shared \
		--disable-doc \
		--disable-asm \
		--with-libgpg-error-prefix=$STATIC_LIBS_PATH

	make -j"$(nproc)"
	make install
}

build_cares() {
	log "Building c-ares dep..."
	. fetch_archive "$CARES_URL"

	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-static -L$STATIC_LIBS_PATH/lib" \
		./configure \
		--host=aarch64-linux-musleabi \
		--prefix=$STATIC_LIBS_PATH \
		--enable-static \
		--disable-shared

	make -j"$(nproc)"
	make install
}

build_speexdsp() {
	log "Building SpeexDSP dep..."
	. fetch_repo "$SPEEXDSP_REPO"

	./autogen.sh
	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-static -L$STATIC_LIBS_PATH/lib" \
		./configure \
		--host=aarch64-linux-musleabi \
		--prefix=$STATIC_LIBS_PATH \
		--enable-static \
		--disable-shared \
		--disable-examples

	make -j"$(nproc)"
	make install
}

build_libusb() {
	log "Building libusb dep..."
	. fetch_repo "$LIBUSB_REPO"

	./autogen.sh
	CC='aarch64-linux-musleabi-gcc' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -fPIC" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -static" \
		./configure \
		--host=aarch64-linux-musleabi \
		--prefix=$STATIC_LIBS_PATH \
		--disable-shared \
		--enable-static \
		--disable-udev

	make -j"$(nproc)"
	make install
}

build_tshark() {
	log "Building tshark..."
	. fetch_repo $WIRESHARK_REPO

	mkdir build && cd build
	# Build lemon for the host system
	mkdir -p /usr/share/lemon
	cp ../tools/lemon/lempar.c /usr/share/lemon/
	gcc -o lemon ../tools/lemon/lemon.c
	cp ../tools/lemon/lempar.c ./

	# Create a toolchain file
	cat >aarch64-linux-musl-toolchain.cmake <<EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-musleabi-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-musleabi-g++)
set(CMAKE_C_FLAGS "-static -fPIC")
set(CMAKE_CXX_FLAGS "-static -fPIC")
set(CMAKE_EXE_LINKER_FLAGS "-static")

set(CMAKE_FIND_ROOT_PATH $STATIC_LIBS_PATH /opt/cross)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Specify the path to libm.a
set(M_LIBRARY "/opt/cross/aarch64-linux-musleabi/lib/libm.a")
set(M_INCLUDE_DIR "/opt/cross/aarch64-linux-musleabi/include")
EOF

	CC='aarch64-linux-musleabi-gcc -static' \
		CFLAGS="-static -I$STATIC_LIBS_PATH/include -I/opt/cross/aarch64-linux-musleabi/include -fPIC" \
		LDFLAGS="-L$STATIC_LIBS_PATH/lib -L/opt/cross/aarch64-linux-musleabi/lib -static -s" \
		PKG_CONFIG_PATH="$STATIC_LIBS_PATH/lib/pkgconfig" \
		cmake \
		-DENABLE_STATIC=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_wireshark=OFF \
		-DCMAKE_INSTALL_PREFIX=$STATIC_LIBS_PATH \
		-DGCRYPT_INCLUDE_DIR=$STATIC_LIBS_PATH/include \
		-DGCRYPT_LIBRARY=$STATIC_LIBS_PATH/lib/libgcrypt.a \
		-DGPG_ERROR_INCLUDE_DIR=$STATIC_LIBS_PATH/include \
		-DGPG_ERROR_LIBRARY=$STATIC_LIBS_PATH/lib/libgpg-error.a \
		-DCARES_INCLUDE_DIR=$STATIC_LIBS_PATH/include \
		-DCARES_LIBRARY=$STATIC_LIBS_PATH/lib/libcares.a \
		-DSPEEXDSP_INCLUDE_DIR=$STATIC_LIBS_PATH/include \
		-DSPEEXDSP_LIBRARY=$STATIC_LIBS_PATH/lib/libspeexdsp.a \
		-DM_INCLUDE_DIR=/opt/cross/aarch64-linux-musleabi/include \
		-DM_LIBRARY=/opt/cross/aarch64-linux-musleabi/lib/libm.a \
		-DPCAP_INCLUDE_DIR=$STATIC_LIBS_PATH/include \
		-DPCAP_LIBRARY=$STATIC_LIBS_PATH/lib/libpcap.a \
		-DLIBUSB_INCLUDE_DIR=$STATIC_LIBS_PATH/include/libusb-1.0 \
		-DLIBUSB_LIBRARIES=$STATIC_LIBS_PATH/lib/libusb-1.0.a \
		-DCMAKE_MODULE_PATH="$(pwd)/../cmake/modules" \
		-DCMAKE_VERBOSE_MAKEFILE=ON \
		-DBUILD_USBDump=ON \
		-DENABLE_PCAP=ON \
		-DENABLE_LIBUSB=ON \
		-DLEMON_EXECUTABLE="$(pwd)/lemon" \
		-DCMAKE_TOOLCHAIN_FILE=aarch64-linux-musl-toolchain.cmake \
		.. || true

	make -j"$(nproc)" VERBOSE=1 2>&1 | tee /log/make_output.log || true
}

build_libusb
build_cares
build_libnl
build_libpcap
build_openssl
build_zlib
build_brotli
build_glib
build_gpg_error
build_gcrypt
build_speexdsp
build_tshark
