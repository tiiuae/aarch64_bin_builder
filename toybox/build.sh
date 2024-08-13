#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
TOYBOX_REPO="https://github.com/landley/toybox.git"

log "Starting Toybox build process..."
. fetch_repo $TOYBOX_REPO

log "Building Toybox"
CROSS_COMPILE=aarch64-linux-musleabi- LDFLAGS=--static make defconfig toybox
verify_build toybox
