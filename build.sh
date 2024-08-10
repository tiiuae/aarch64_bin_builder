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

    # Build the Docker image with BuildKit enabled
    DOCKER_BUILDKIT=1 docker build --no-cache -t "${app_name}-builder" "$app_dir"

    # Run the container to build the application, using a named volume for caching
    docker run --rm -v "$(pwd):/repo" -v "${app_name}-cache:/build-cache" "${app_name}-builder"

    # Remove the builder image after the build is complete
    echo "Removing ${app_name}-builder image..."
    docker rmi "${app_name}-builder"

    echo "Finished building $app_name"
}

# Function to clean up unused Docker resources related to builders
cleanup_docker() {
    echo "Cleaning up Docker resources related to builders..."
    for dir in */; do
        app_name=$(basename "$dir")
        if docker image inspect "${app_name}-builder" &>/dev/null; then
            echo "Removing ${app_name}-builder image..."
            docker rmi "${app_name}-builder" >/dev/null 2>&1
        fi
    done

    # Remove any dangling images
    docker image prune -f
}

# Main execution
if [ "$1" = "--cleanup" ]; then
    cleanup_docker
    exit 0
fi

if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        build_app "$1"
    else
        echo "Directory $1 does not exist"
        exit 1
    fi
else
    echo "Building all applications..."
    for dir in */; do
        if [ -f "${dir}build.sh" ] && [ -f "${dir}Dockerfile" ]; then
            build_app "$dir"
        fi
    done
fi

echo "All builds completed. Binaries are in $BINARIES_DIR"
