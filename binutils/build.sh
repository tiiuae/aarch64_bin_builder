#!/bin/bash
set -euo pipefail

# Configuration
VERSION=2.41
BINUTILS_URL="http://ftp.gnu.org/gnu/binutils/binutils-$VERSION.tar.gz"
LOG_FILE="build_binutils.log"
BINARIES_DIR="/repo/binaries"
EXPECTED_BINS="elfedit addr2line strip-new cxxfilt objcopy readelf strings ranlib ar nm-new objdump size"

# Function for logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function for error handling
handle_error() {
    log "Error occurred on line $1"
    exit 1
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Start build process
log "Starting Binutils build process for aarch64 (static)"

# Download Binutils
if [[ ! -s "binutils-$VERSION.tar.gz" ]]; then
    log "Downloading Binutils"
    wget -q "$BINUTILS_URL"

    # Extract Binutils
    log "Extracting Binutils"
    tar xzf "binutils-$VERSION.tar.gz"
    cd "binutils-$VERSION"
fi

# Fix some broken symbols in the MUSL toolchain
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

# Configure Binutils
log "Configuring Binutils"
CC="aarch64-linux-musleabi-gcc -static" \
    CXX="aarch64-linux-musleabi-g++ -static" \
    CFLAGS="-static -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" \
    ./configure --host=aarch64-linux-musleabi \
    --disable-shared \
    --enable-static \
    --disable-werror \
    --disable-gprof \
    --disable-gprofng \
    --disable-nls

# Build Binutils
log "Building Binutils"
make LDFLAGS="--static -s" -j"$(nproc)"

log "Binutils built successfully"

# Verify build
for f in $EXPECTED_BINS; do
    if [ ! -f "binutils/$f" ]; then
        log "Error: $f binary not found"
        exit 1
    fi
    cp "binutils/$f" "$BINARIES_DIR/$f"
    log "$f binary copied to $BINARIES_DIR/$f"
done
