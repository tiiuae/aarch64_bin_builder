# Use the muslcross container as the base image
FROM aarch64_musl_cross:v1.0

# Copy the build script into the container
COPY build.sh /build/

# Make the build script executable
RUN chmod +x /build/build.sh

# Set the entrypoint to the build script
ENTRYPOINT ["/build/build.sh"]
