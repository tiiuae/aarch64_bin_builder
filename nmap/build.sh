#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
export OPENSSL_VERSION="1.1.1q"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export NMAP_REPO="https://github.com/nmap/nmap.git"
export EXPECTED_BINARIES="nmap ncat/ncat nping/nping"

build_openssl() {
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests
	make -j"$MAKE_JOBS"
}

build_nmap() {
	. fetch_repo $NMAP_REPO

	CC='aarch64-linux-musleabi-gcc -static -fPIC' \
		CXX='aarch64-linux-musleabi-g++ -static -static-libstdc++ -fPIC' \
		LD=aarch64-linux-musleabi-ld \
		LDFLAGS="-L/tmp/openssl-${OPENSSL_VERSION} -s" \
		./configure --without-ndiff \
		--without-zenmap \
		--without-nmap-update \
		--with-pcap=linux \
		--with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
		--host="$HOST"

	# Don't build the libpcap.so file
	sed -i -e 's/shared\: /shared\: #/' libpcap/Makefile
	sed -i -e 's/shared\: /shared\: #/' libz/Makefile
	make -j"$MAKE_JOBS"
}

log "Starting nmap build process..."
log "Building openSSL dep..."
wrunf build_openssl
log "Building Nmap..."
wrunf build_nmap
verify_build -b "$EXPECTED_BINARIES"
#NOTE: We need to manually package the nmap NSE scripts
tar cfz "$BINARIES_DIR/nmap_usrsharenmap.tar.gz" nselib/* scripts/* docs/nmap.dtd nmap-mac-prefixes nmap-os-db nmap-protocols nmap-rpc nmap-service-probes nmap-services docs/nmap.xsl nse_main.lua
