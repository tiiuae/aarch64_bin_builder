# 🛠️ Aarch64 Static Cross-Compilation Toolchain

This repository hosts an aarch64 MUSL-based cross-compilation toolchain designed to produce statically linked binaries for commonly needed tools

## 🚀 Usage

The [latest release](https://github.com/tiiuae/aarch64_bin_builder/releases/latest) will always have all binaries built by a [github-action](https://github.com/tiiuae/aarch64_bin_builder/blob/main/.github/workflows/build.yml).
If you want to extend, or build locally, follow these simple steps:

1. Check out the repository
2. Build the base builder Docker image:

```sh
docker build -t aarch64_musl_cross:v1.0 . -f .cfg/Dockerfile
```

> Note: Using _aarch64_musl_cross:v1.0_ as the tag is crucial!

2. Build the tools:

- To build all tools:

```sh
./build.sh
```

- To build a specific tool:

```sh
./build.sh <foldername>
```

### 📜 Script usage

This repository hosts a [utility script](static.sh) that lets you list and download all binaries from the latest release.
Ideally all downloaded binaries never touch the disk but only live in memory. As a fallback `/tmp` directory will be used.
Either copy the script manually or source it from this repository:

```sh
source <(curl -SsfL https://raw.githubusercontent.com/tiiuae/aarch64_bin_builder/main/static.sh)
# or
source <(wget -qO- https://raw.githubusercontent.com/tiiuae/aarch64_bin_builder/main/static.sh)
# or
source <(python3 -c "import urllib.request; print(urllib.request.urlopen('https://raw.githubusercontent.com/tiiuae/aarch64_bin_builder/main/static.sh').read().decode())")
```

With this you have access to:

```sh
# list all available binaries
static ls
# download the request binary
static dl <bin>
```

## Disclaimer

The binaries are packed with [UPX](https://github.com/upx/upx) to reduce their footprint drastically, allowing for faster download speeds and usage on
memory/disk bottlenecked devices. That said, the build process is transparent and open source, so if you distrust the binary, please read the code or compile locally.

## Contributing 🤝

Contributions are welcome! Please feel free to submit a pull request or open an issue for any bugs, feature requests, or improvements.

## License 📜

This project is licensed under the Apache License. See the [LICENSE](LICENSE.md) file for details.
