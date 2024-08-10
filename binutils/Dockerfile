# Use the muslcross container as the base image
FROM muslcross

# Copy the build script into the container
COPY build.sh /build/
RUN chmod +x /build/build.sh

# Set the entrypoint to the build script
ENTRYPOINT ["/build/build.sh"]
