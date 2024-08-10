FROM debian:bookworm
LABEL org.opencontainers.image.authors="christopher.krah@unikie.com"

ENV DEBIAN_FRONTEND=noninteractive
# Install build tools
RUN apt-get update && \
    apt-get upgrade -yy && \
    apt-get install -yy --no-install-recommends \
        automake            \
        bison               \
        build-essential     \
        curl                \
        file                \
        flex                \
        git                 \
        libtool             \
        libtool-bin         \
        pkg-config          \
        python3             \
        texinfo             \
        vim                 \
        git                 \
        make                \
        unzip               \
        wget                \
        ca-certificates     \
        ninja-build         \
        autoconf            \
        cmake               \
        meson               \
    && rm -rf /var/lib/apt/lists/*

# Configure musl-cross-make
COPY config.mak /tmp/config.mak

# Install musl-cross-make
WORKDIR /build
RUN git clone --depth=1 "https://github.com/richfelker/musl-cross-make.git"
WORKDIR /build/musl-cross-make
# This is configuring musl-cross-make to build a cross-compiler for aarch64
RUN cp /tmp/config.mak config.mak && make -j"$(nproc)" && make -j"$(nproc)" install

ENV PATH=$PATH:/opt/cross/
ENV PATH="/opt/cross/bin:${PATH}"

WORKDIR /build

CMD ["/bin/bash"]
