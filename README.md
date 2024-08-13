# 🛠️ Aarch64 Static Cross-Compilation Toolchain

This repository hosts an aarch64 MUSL-based cross-compilation toolchain designed to produce statically linked aarch64 binaries for essential tools used in our penetration testing engagements.

## 🚀 Usage

To get started, follow these simple steps:

1. Build the Docker image:

```sh
docker build -t aarch64_musl_cross:v1.0 . -f Dockerfile
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

## TODOs

- [ ] Add more tooling
- [ ] Decide if we want to abuse the GitHub CI for building
