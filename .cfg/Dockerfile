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
    git \
    libtool \
    pkgconf \
    python3 \
    texinfo \
    vim \
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
    perl


ENV BINARIES_DIR="/repo/binaries"

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

ENV PATH=$PATH:/opt/cross/
ENV PATH="/opt/cross/bin:${PATH}"

WORKDIR /build

CMD ["/bin/bash"]
