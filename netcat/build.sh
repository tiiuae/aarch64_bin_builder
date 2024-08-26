#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
NETCAT_URL="https://sourceforge.net/projects/netcat/files/latest/download"

build_netcat() {
	. fetch_archive $NETCAT_URL

	wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
	chmod +x config.sub
	./configure --host="$HOST"
	make -j"$(nproc)"
}

log "Building netcat"
wrunf build_netcat
verify_build -b netcat -p src
