#!/bin/bash
set -euo pipefail
trap 'handle_err $LINENO' ERR

# Configuration
BINUTILS_VERSION=2.41
BINUTILS_URL="http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.gz"
EXPECTED_BINS="elfedit addr2line strip-new cxxfilt objcopy readelf strings ranlib ar nm-new objdump size"

log "Starting Binutils build process..."
. fetch_archive $BINUTILS_URL

# Fix some broken symbols in the MUSL toolchain
log "Patching Binutils for MUSL compatibility"
# Replace off64_t with off_t
sed -i 's/off64_t/off_t/g' gprofng/libcollector/iolib.c
# Replace specific instances of (off64_t) with (off_t)
sed -i 's/(off64_t) 0/(off_t) 0/g' gprofng/libcollector/iolib.c
# Replace the function declaration
sed -i 's/static int mapBuffer (char \*fname, Buffer \*buf, off64_t foff);/static int mapBuffer (char *fname, Buffer *buf, off_t foff);/' gprofng/libcollector/iolib.c
# Replace the function definition
sed -i 's/mapBuffer (char \*fname, Buffer \*buf, off64_t foff)/mapBuffer (char *fname, Buffer *buf, off_t foff)/' gprofng/libcollector/iolib.c
# Replace off64_t with off_t
sed -i 's/off64_t/off_t/g' gprofng/libcollector/mmaptrace.c
# Replace the mmap64 assignment
sed -i 's/__real_mmap64 = dlsym (dlflag, "mmap64");/__real_mmap64 = __real_mmap;  \/\/ Use mmap instead of mmap64/' gprofng/libcollector/mmaptrace.c

log "Building Binutils"
CFLAGS="-static -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
	./configure --host="$HOST" \
	--disable-shared \
	--enable-static \
	--disable-werror \
	--disable-gprof \
	--disable-gprofng \
	--disable-nls
make LDFLAGS="--static -s" -j"$(nproc)"
verify_build -b "$EXPECTED_BINS" -p binutils
