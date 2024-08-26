#!/bin/bash

# Directory to store all built binaries
BINARIES_DIR="$(pwd)/binaries"
mkdir -p "$BINARIES_DIR"

TMP_LOG_DIR=$(mktemp -d)
TMP_LOG="$TMP_LOG_DIR/build.log"

# Function to build a single application
build_app() {
	local app_dir="$1"
	local app_name
	app_name=$(basename "$app_dir")
	echo "Building $app_name..."

	# Build the Docker image with BuildKit enabled
	docker build --no-cache -t "${app_name}-builder" "$app_dir"

	# Run the container to build the application, using a named volume for caching
	docker run --rm \
		-v "$(pwd):/repo" \
		-v "${app_name}-cache:/build-cache" \
		-v "$TMP_LOG_DIR:/build_log" \
		"${app_name}-builder"
	exit_status=$?

	# If the exit status is non-zero (error occurred)
	if [ $exit_status -ne 0 ]; then
		echo "Error occurred. Output:"
		cat "$TMP_LOG"
		rm -Rf "$TMP_LOG_DIR"
		exit $exit_status
	fi

	# Remove the builder image after the build is complete
	docker rmi "${app_name}-builder" >/dev/null 2>&1

	echo "  [DONE]"
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

if [ -n "$1" ]; then
	if [ -d "$1" ]; then
		build_app "$1"
	else
		echo "Directory $1 does not exist"
		exit 1
	fi
else
	if [ "$1" = "--cleanup" ]; then
		cleanup_docker
		exit 0
	else
		echo "Building all applications..."
		for dir in */; do
			if [ -f "${dir}build.sh" ] && [ -f "${dir}Dockerfile" ]; then
				build_app "$dir"
			fi
		done
	fi
fi
rm -Rf "$TMP_LOG_DIR"
