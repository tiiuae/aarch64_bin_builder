#!/bin/sh

set -e

REPO_URL="https://api.github.com/repos/tiiuae/aarch64_bin_builder/releases/latest"
TEMP_DIR="/dev/shm"

# Create TEMP_DIR if it doesn't exist
mkdir -p "$TEMP_DIR"

add_to_path() {
	case ":$PATH:" in
	*":$TEMP_DIR:"*) ;;
	*) PATH="$TEMP_DIR:$PATH" ;;
	esac
	export PATH
}

_download() {
	url="$1"
	output="$2"

	if command -v curl >/dev/null 2>&1; then
		curl -sSL -o "$output" "$url"
	elif command -v wget >/dev/null 2>&1; then
		wget -q -O "$output" "$url"
	elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
		if command -v python3 >/dev/null 2>&1; then
			python3 -c "import urllib.request; urllib.request.urlretrieve('$url', '$output')" 2>/dev/null
		elif command -v python >/dev/null 2>&1; then
			python -c "import urllib.request; urllib.request.urlretrieve('$url', '$output')" 2>/dev/null ||
				python -c "import urllib2; urllib2.urlretrieve('$url', '$output')"
		fi
	elif command -v perl >/dev/null 2>&1; then
		perl -e "use LWP::Simple; getstore('$url', '$output');"
	elif command -v php >/dev/null 2>&1; then
		php -r "file_put_contents('$output', file_get_contents('$url'));"
	else
		echo "Error: No suitable download method found." >&2
		return 1
	fi
}

_fetch_url() {
	url="$1"
	host="${url#http://}"
	host="${host#https://}"
	host="${host%%/*}"
	path="/${url#*://*/}"

	# shellcheck disable=SC3025
	exec 3</dev/tcp/"$host"/80
	printf "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" >&3
	sed '1,/^$/d' <&3
	exec 3<&-
}

list_binaries() {
	assets=$(_download "$REPO_URL" - | sed -n 's/.*"name": "\([^"]*\)".*/\1/p' | sed '1d' | sort -V)

	if [ -n "$assets" ]; then
		echo "Available binaries:"
		echo "$assets" | column
	else
		echo "Error: Unable to fetch binary list." >&2
		return 1
	fi
}

dl() {
	binary="$1"
	[ -z "$binary" ] && {
		echo "Error: Please specify a binary to download." >&2
		return 1
	}

	release_info=$(_download "$REPO_URL" -)
	asset_url=$(echo "$release_info" | sed -n 's/.*"browser_download_url": "\([^"]*'"$binary"'[^"]*\)".*/\1/p')

	[ -z "$asset_url" ] && {
		echo "Error: Binary '$binary' not found." >&2
		return 1
	}

	echo "Downloading $binary from $asset_url into $TEMP_DIR..."
	if _download "$asset_url" "$TEMP_DIR/$binary"; then
		chmod +x "$TEMP_DIR/$binary"
		echo "Successfully installed $binary to $TEMP_DIR/$binary"
		add_to_path
	else
		echo "Error: Failed to download $binary." >&2
		return 1
	fi
}

static() {
	case "$1" in
	ls) list_binaries ;;
	path) add_to_path ;;
	dl) dl "$2" ;;
	*) echo "Usage: static {ls|dl <binary_name>|path}" ;;
	esac
}

# Check if the script is being sourced
# shellcheck disable=SC3028
if [ "${0}" != "${BASH_SOURCE:-$0}" ]; then
	# Script is being sourced, export functions
	add_to_path
	# Use command to avoid issues with functions overriding built-ins

	# shellcheck disable=SC3045
	command -v static >/dev/null 2>&1 || export -f static
	# shellcheck disable=SC3045
	command -v list_binaries >/dev/null 2>&1 || export -f list_binaries
	# shellcheck disable=SC3045
	command -v dl >/dev/null 2>&1 || export -f dl
	# shellcheck disable=SC3045
	command -v add_to_path >/dev/null 2>&1 || export -f add_to_path
else
	# Script is being run directly, call static function
	static "$@"
fi
