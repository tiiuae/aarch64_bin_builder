# 🛠️ Aarch64 Static Cross-Compilation Toolchain

This repository hosts an aarch64 MUSL-based cross-compilation toolchain designed to produce statically linked binaries for commonly needed tools

## 🚀 Usage

The [latest release](https://github.com/tiiuae/pentesting_toolbelt/releases/tag/main) will always have all binaries built by a [github-action](https://github.com/tiiuae/pentesting_toolbelt/blob/main/.github/workflows/build.yml).
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

## Contributing 🤝

Contributions are welcome! Please feel free to submit a pull request or open an issue for any bugs, feature requests, or improvements.

## License 📜

This project is licensed under the Apache License. See the [LICENSE](LICENSE.md) file for details.