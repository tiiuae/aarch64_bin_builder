# Use the muslcross container as the base image
FROM muslcross

# Set environment variables
ENV PATH="/opt/cross/bin:${PATH}"

# Install necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    make \
    && rm -rf /var/lib/apt/lists/*

# Set up work directory
WORKDIR /build

# Copy the build script into the container
COPY build.sh /build/

# Make the build script executable
RUN chmod +x /build/build.sh

# Set the entrypoint to the build script
ENTRYPOINT ["/build/build.sh"]
