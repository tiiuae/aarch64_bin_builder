#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
GZIP_VERSION="1.13"
GZIP_REPO="https://ftp.gnu.org/gnu/gzip/gzip-${GZIP_VERSION}.tar.xz"

build_gzip() {
	. fetch_archive $GZIP_REPO

	./configure --host="$HOST"
	make -j"$MAKE_JOBS"
}

log "Building Gzip"
wrunf build_gzip
verify_build gzip
