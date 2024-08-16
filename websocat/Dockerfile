FROM aarch64_musl_cross:v1.0

# Add dependencies
# hadolint ignore=SC1091
RUN apk add --no-cache \
    rustup && \
    rustup-init -yq && \
    . "$HOME/.cargo/env" && \
    rustup target add aarch64-unknown-linux-musl

# Copy the build script into the container
COPY build.sh /build/

# Make the build script executable
RUN chmod +x /build/build.sh

# Set the entrypoint to the build script
ENTRYPOINT ["/build/build.sh"]
