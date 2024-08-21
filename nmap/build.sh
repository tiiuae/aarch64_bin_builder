#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
OPENSSL_VERSION="1.1.1q"
OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
NMAP_REPO="https://github.com/nmap/nmap.git"
EXPECTED_BINARIES="nmap ncat/ncat nping/nping"

build_openssl() {
	log "Building openSSL dep..."
	. fetch_archive $OPENSSL_URL
	./Configure no-shared linux-aarch64 no-tests
	make -j"$(nproc)"
	log "Finished building static OpenSSL dependency"
}

build_nmap() {
	log "Building Nmap"
	. fetch_repo $NMAP_REPO

	CFLAGS="-static -fPIC" \
		CXXFLAGS="-static -fPIC -static-libstdc++" \
		LD=/opt/cross/bin/aarch64-linux-musleabi-ld \
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
	make -j"$(nproc)"
}

build_openssl
build_nmap
verify_build -b "$EXPECTED_BINARIES"
#NOTE: We need to manually package the nmap NSE scripts
tar cfz "$BINARIES_DIR/nmap_usrsharenmap.tar.gz" nselib/* scripts/* docs/nmap.dtd nmap-mac-prefixes nmap-os-db nmap-protocols nmap-rpc nmap-service-probes nmap-services docs/nmap.xsl nse_main.lua
