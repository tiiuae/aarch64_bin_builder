#!/bin/bash

# Directory to store all built binaries
BINARIES_DIR="$(pwd)/binaries"
mkdir -p "$BINARIES_DIR"

TMP_LOG_DIR=$(mktemp -d)

# Function to build a single application
build_app() {
	local app_dir="$1"
	local app_name
	app_name=$(basename "$app_dir")
	echo "Building $app_name..."

	# Create a temporary log file for this build
	local temp_build_log
	temp_build_log=$(mktemp)

	# Build the Docker image
	docker build --no-cache -t "${app_name}-builder" "$app_dir"

	# Run the container to build the application
	docker run --rm \
		-v "$(pwd):/repo" \
		-v "${app_name}-cache:/build-cache" \
		-v "$temp_build_log:/build_log/build.log" \
		"${app_name}-builder"
	exit_status=$?

	# Copy the temporary log to a permanent location and append the exit status
	local permanent_log="$TMP_LOG_DIR/${app_name}_build.log"
	cp "$temp_build_log" "$permanent_log"
	echo "Docker build exit status: $exit_status" >>"$permanent_log"

	# Remove the temporary log file
	rm "$temp_build_log"

	# If the exit status is non-zero (error occurred)
	if [ $exit_status -ne 0 ]; then
		echo "Error occurred. Output:"
		cat "$permanent_log"
		echo "Full log available at: $permanent_log"
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

# Cleanup function to remove all logs
cleanup_logs() {
	echo "Cleaning up build logs..."
	rm -rf "$TMP_LOG_DIR"
}

if [[ $# -eq 0 ]]; then
	echo "Building all applications..."
	for dir in */; do
		if [ "$dir" != "$(basename "$BINARIES_DIR")/" ]; then
			build_app "$dir"
		fi
	done
elif [[ $1 == "--cleanup" ]]; then
	cleanup_docker
	cleanup_logs
else
	for arg in "$@"; do
		if [[ -d $arg ]]; then
			build_app "$arg"
		else
			echo "Application directory not found: $arg" >&2
			exit 1
		fi
	done
fi
