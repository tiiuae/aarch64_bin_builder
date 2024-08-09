#!/bin/bash
set -euo pipefail

# Directory to store all built binaries
BINARIES_DIR="$(pwd)/binaries"
mkdir -p "$BINARIES_DIR"

# Function to build a single application
build_app() {
    local app_dir="$1"
    local app_name=$(basename "$app_dir")
    echo "Building $app_name..."

    # Build the Docker image
    docker build -t "${app_name}-builder" "$app_dir"

    # Run the container to build the application
    docker run --rm -v "$(pwd):/repo" "${app_name}-builder"

    echo "Finished building $app_name"
}

# Check the first argument for a Directory
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        build_app "$1"
        exit 0
    else
        echo "Directory $1 does not exist"
        exit 1
    fi
else
    echo "Building all applications..."
    # Iterate through all subdirectories
    for dir in */; do
        if [ -f "${dir}build.sh" ] && [ -f "${dir}Dockerfile" ]; then
            build_app "$dir"
        fi
    done
fi

echo "All builds completed. Binaries are in $BINARIES_DIR"
