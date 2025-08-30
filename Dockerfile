# Dockerfile for Ubuntu-based build environment
# Base: Ubuntu LTS for .deb packaging compatibility
FROM ubuntu:24.04

ARG OS_ARCH=amd64

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and upgrade system and install base dependencies
RUN apt-get update && apt-get dist-upgrade -y && apt-get install --no-install-recommends --no-install-suggests -y \
    # General utilities
    curl \
    wget \
    git \
    vim \
    unzip \
    tar \
    gzip \
    jq \
    yq \
    openssh-client \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release \
    bash \
    apt-transport-https \
    software-properties-common \
    sudo \
    # C/C++ build tools
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Additional compiling tools and interpreters
    bison \
    flex \
    byacc \
    ninja-build \
    meson \
    qemu-utils \
    # Debian/Ubuntu packaging tools
    debhelper \
    dh-make \
    devscripts \
    fakeroot \
    lintian \
    quilt \
    dpkg-dev

# Create dedicated user for build
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder \
    # Adds builder to necessary groups
    && usermod -a -G sudo builder \
    # Configures sudo without password for builder
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    # Creates directory for temporary builds and configure fakeroot
    && mkdir -p /home/builder/{workspace,tmp,build} \
    && chown -R builder:builder /home/builder \
    && chmod -R 775 /home/builder \
    # Configure fakeroot
    && mkdir -p /home/builder/.fakeroot \
    && chown builder:builder /home/builder/.fakeroot \
    && chmod 775 /home/builder/.fakeroot

# Switch to user builder and set workdir
USER builder
WORKDIR /home/builder

# Configures Git for user builder
RUN git config --global user.name "Bytehawks GitHub autobuilder" \
    && git config --global user.email "autobuild@bytehawks.org" \
    && git config --global init.defaultBranch main

# Environment variables for user builder
ENV DEBFULLNAME="Bytehawks GitHub autobuilder"
ENV DEBEMAIL="autobuild@bytehawks.org"
ENV TMPDIR="/home/builder/tmp"
ENV HOME="/home/builder"

# Default command
CMD ["/bin/bash"]
