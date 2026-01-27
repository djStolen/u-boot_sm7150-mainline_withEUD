# Use the official Ubuntu 24.04 LTS image
FROM ubuntu:24.04

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Essential tools for VS Code Server to install/run
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tar \
    python3 \
    git \
    libtool \
    autoconf \
    pkg-config \
    libusb-1.0-0-dev \
    libftdi1-dev \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Additional tools
RUN apt-get update && apt-get install -y \
    adb \
    fastboot \
    gcc-aarch64-linux-gnu \
    bison flex \
    xxd \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libgnutls28-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Expose the default ADB port
EXPOSE 5037

# Default command
CMD ["adb", "--version"]