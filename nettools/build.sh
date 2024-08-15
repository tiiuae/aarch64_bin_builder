#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
NETTOOLS_REPO="https://github.com/ecki/net-tools"
EXPECTED_BINARIES="netstat arp ifconfig iptunnel route"

log "Starting Nettools build process..."
. fetch_repo "$NETTOOLS_REPO"

# Set the default options for all 44 options..
printf "%0.s\n" {1..44} | make config

CC=aarch64-linux-musleabi-gcc \
	CFLAGS="-I/usr/include -I/usr/include/bluetooth" \
	LDFLAGS="--static -s" \
	make -j"$(nproc)"
verify_build -b "$EXPECTED_BINARIES"
