FROM alpine:3.20
LABEL org.opencontainers.image.authors="christopher.krah@unikie.com"

# Install build tools and dependencies
RUN apk add --no-cache \
    automake \
    autoconf \
    bison \
    build-base \
    curl \
    file \
    flex \
    gettext \
    gettext-dev \
    git \
    libtool \
    pkgconf \
    python3 \
    texinfo \
    neovim \
    make \
    unzip \
    wget \
    ca-certificates \
    ninja \
    cmake \
    meson \
    bash \
    gawk \
    sed \
    libstdc++ \
    g++ \
    gcc \
    linux-headers \
    util-linux \
    upx \
    perl


# Configure Rust
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=SC1091
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo 'source $HOME/.cargo/env' >> /root/.bashrc && \
    . "$HOME/.cargo/env" && \
    rustup target add aarch64-unknown-linux-musl


ENV BINARIES_DIR="/repo/binaries"
ENV PATH="/root/.cargo/bin:${PATH}"


# Set up some common helper functions
COPY .cfg/fetch_repo /bin/
COPY .cfg/fetch_archive /bin/
COPY .cfg/log /bin/
COPY .cfg/handle_err /bin/
COPY .cfg/verify_build /bin/

# Configure musl-cross-make
COPY .cfg/musl_cross_cfg.mak /tmp/config.mak

# Install musl-cross-make
WORKDIR /build
RUN git clone --depth=1 "https://github.com/richfelker/musl-cross-make.git"
WORKDIR /build/musl-cross-make
# This is configuring musl-cross-make to build a cross-compiler for aarch64
RUN cp /tmp/config.mak . && \
    make -j"$(nproc)" && \
    make -j"$(nproc)" install

# Enable cargo and rust toolchain
ENV PATH=$PATH:/opt/cross/
ENV PATH="/opt/cross/bin:${PATH}"

# Setup C/CPP environment variables for cross-compilation
ENV CC="aarch64-linux-musleabi-gcc"
ENV CXX="aarch64-linux-musleabi-g++"
ENV CFLAGS="-static -O2"
ENV CXXFLAGS="-static -O2"
ENV LDFLAGS="-static -s"
ENV HOST="aarch64-linux-musleabi"

# Setup RUST environment variables for cross-compilation
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER="aarch64-linux-musleabi-gcc"
ENV CC_aarch64_unknown_linux_musl="aarch64-linux-musleabi-gcc"
ENV RUSTFLAGS="-C opt-level=z -C target-feature=+crt-static -C panic=abort -C lto=fat -C codegen-units=1 -C embed-bitcode=yes"

WORKDIR /build

CMD ["/bin/bash"]
