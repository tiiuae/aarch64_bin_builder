#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
TAR_VERSION="1.35"
TAR_REPO="https://ftp.gnu.org/gnu/tar/tar-${TAR_VERSION}.tar.xz"

build_tar() {
	. fetch_archive $TAR_REPO

	./configure --host="$HOST"
	make -j"$(/bin/get_cores)"
}

log "Building Tar"
wrunf build_tar
verify_build -b "tar" -p "src"
