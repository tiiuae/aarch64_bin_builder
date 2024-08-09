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
        pkg-config          \
        python3             \
        texinfo             \
        vim                 \
        wget                \
        ca-certificates

# Configure musl-cross-make
COPY config.mak /tmp/config.mak

# Install musl-cross-make
WORKDIR /build
RUN git clone --depth=1 https://github.com/richfelker/musl-cross-make.git
WORKDIR /build/musl-cross-make
RUN cp /tmp/config.mak config.mak && make -j"$(nproc)" && make -j"$(nproc)" install

ENV PATH=$PATH:/opt/cross/
CMD ["/bin/bash"]
