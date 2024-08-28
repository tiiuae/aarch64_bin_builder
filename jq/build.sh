#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR
. wrunf

# -- EDIT BELOW THIS LINE --

# Configuration
export JQ_VERSION="1.7.1"
export JQ_URL="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz"

build_jq() {
	. fetch_archive $JQ_URL

	./configure --host="$HOST" --with-oniguruma=builtin
	make LDFLAGS="-all-static" -j"$(/bin/get_cores)"
}

log "Building jq"
wrunf build_jq
verify_build jq
