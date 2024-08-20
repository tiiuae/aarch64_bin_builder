#!/bin/bash
set -e

REPO_URL="https://api.github.com/repos/tiiuae/aarch64_bin_builder/releases/latest"
TEMP_DIR="/dev/shm"

if [[ ! -w "$TEMP_DIR" ]]; then
	TEMP_DIR="/tmp"
	[[ ! -w "$TEMP_DIR" ]] && TEMP_DIR="$HOME/.cache"
fi

add_to_path() {
	[[ ":$PATH:" != *":$TEMP_DIR:"* ]] && export PATH="$TEMP_DIR:$PATH"
}

_download() {
	local url="$1"
	local output="$2"

	if command -v curl &>/dev/null; then
		curl -sSL -o "$output" "$url"
	elif command -v wget &>/dev/null; then
		wget -q -O "$output" "$url"
	elif command -v python3 &>/dev/null || command -v python &>/dev/null; then
		(python3 -c "import urllib.request; urllib.request.urlretrieve('$url', '$output')" 2>/dev/null) ||
			(python -c "import urllib.request; urllib.request.urlretrieve('$url', '$output')" 2>/dev/null) ||
			(python -c "import urllib2; urllib2.urlretrieve('$url', '$output')")
	elif command -v perl &>/dev/null; then
		perl -e "use LWP::Simple; getstore('$url', '$output');"
	elif command -v php &>/dev/null; then
		php -r "file_put_contents('$output', file_get_contents('$url'));"
	else
		_fetch_url "$url" >"$output"
	fi
}

_fetch_url() {
	local url="$1"
	local host path

	[[ "$url" =~ ^https?://([^/]+)(/.*)$ ]]
	host="${BASH_REMATCH[1]}"
	path="${BASH_REMATCH[2]}"

	exec 3<>"/dev/tcp/${host}/80"
	printf "GET %s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n" "$path" "$host" >&3
	sed '1,/^$/d' <&3
	exec 3>&-
}

ls() {
	local assets
	local term_width
	local column_cmd

	# Fetch assets
	assets=$(_download "$REPO_URL" - | grep -oP '"name": "\K[^"]+' | tail -n +2 | sort -V)

	if [[ -n "$assets" ]]; then
		echo "Available binaries:"

		if command -v tput &>/dev/null; then
			term_width=$(tput cols)
			if command -v column &>/dev/null && column --help 2>&1 | grep -q -- '-c'; then
				column_cmd="column -c $term_width"
				echo "$assets" | $column_cmd
			else
				echo "$assets" | column
			fi
		else
			echo "$assets"
		fi
	else
		echo "Error: Unable to fetch binary list." >&2
		return 1
	fi
}

dl() {
	local binary="$1"
	local asset_url

	[[ -z "$binary" ]] && {
		echo "Error: Please specify a binary to download." >&2
		return 1
	}

	release_info=$(_download "$REPO_URL" -)
	asset_url=$(echo "$release_info" | grep -oP "\"browser_download_url\": \"\K[^\"]+$binary")

	[[ -z "$asset_url" ]] && {
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
	ls) ls ;;
	dl) dl "$2" ;;
	*) echo "Usage: static {list|dl <binary_name>}" ;;
	esac
}

# Check if the script is being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	# Script is being sourced, export functions
	export -f static list dl add_to_path
else
	# Script is being run directly, call static function
	static "$@"
fi
