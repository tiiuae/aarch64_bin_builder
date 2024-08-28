#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
NETTOOLS_REPO="https://github.com/ecki/net-tools"
EXPECTED_BINARIES="netstat arp ifconfig iptunnel route"

build_nettools() {
	. fetch_repo "$NETTOOLS_REPO"

	# Set the default options for all 44 options..
	printf "%0.s\n" {1..44} | make config

	CFLAGS="-I/usr/include -I/usr/include/bluetooth" \
		LDFLAGS="--static -s" \
		make -j"$(/bin/get_cores)"
}

log "Building net-tools"
wrunf build_nettools
verify_build -b "$EXPECTED_BINARIES"
