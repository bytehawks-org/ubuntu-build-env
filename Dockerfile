# Dockerfile for Ubuntu-based build environment
# Base: Ubuntu LTS for .deb packaging compatibility
FROM ubuntu:24.04

ARG OS_ARCH=amd64

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Define software versions
ARG PACKER_VERSION=1.14.1
ARG TERRAFORM_VERSION=1.13.1
ARG GO_VERSION=1.25.0

# Update and upgrade system and install base dependencies
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y \
    # General utilities
    curl \
    wget \
    git \
    vim \
    nano \
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
    ansible \
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
    dpkg-dev \
    # Python3 interpreters and tools
    python3 \
    python3-full \
    python3-pip 

# Install Docker CLI for GitLab CI (Docker-in-Docker scenarios)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=${OS_ARCH} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install GO compiler
RUN curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-${OS_ARCH}.tar.gz" \
    && tar -C /usr/local -xzf "go${GO_VERSION}.linux-${OS_ARCH}.tar.gz" \
    && rm "go${GO_VERSION}.linux-${OS_ARCH}.tar.gz"

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# Install Hashicorp Packer
RUN wget -O /tmp/packer.zip "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_${OS_ARCH}.zip" \
    && unzip -o /tmp/packer.zip -d /tmp/packer \
    && install -m 755 /tmp/packer/packer /usr/local/bin/packer \
    && rm -rf /tmp/packer.zip /tmp/packer

# Install Hashicorp Terraform
RUN wget -O /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${OS_ARCH}.zip" \
    && unzip -o /tmp/terraform.zip -d /tmp/terraform \
    && install -m 755 /tmp/terraform/terraform /usr/local/bin/terraform \
    && rm /tmp/terraform.zip /tmp/terraform

# Create dedicated user for build
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder \
    # Adds builder to necessary groups
    && usermod -a -G sudo builder \
    # Configures sudo without password for builder
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    # Creates directory for temporary builds
    && mkdir -p /home/builder/{workspace,tmp,build} \
    && chown -R builder:builder /home/builder \
    # Configures fakeroot for user builder
    && mkdir -p /home/builder/.fakeroot \
    && chown -R builder:builder /home/builder/.fakeroot

# Switch to user builder and set workdir
USER builder
WORKDIR /home/builder

# Install latest Rust for user builder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && echo 'source ~/.cargo/env' >> ~/.bashrc

# Adds Rust to PATH for user builder
ENV PATH="/home/builder/.cargo/bin:/usr/local/go/bin:${PATH}"

# Installs Rust components for user builder
RUN ~/.cargo/bin/rustup component add \
    rustfmt \
    clippy \
    rust-src \
    && ~/.cargo/bin/cargo install cargo-deb

# Configures Git for user builder
RUN git config --global user.name "Bytehawks GitHub autobuilder" \
    && git config --global user.email "autobuild@bytehawks.org" \
    && git config --global init.defaultBranch main

# Environment variables for user builder
ENV DEBFULLNAME="Bytehawks GitHub autobuilder"
ENV DEBEMAIL="autobuild@bytehawks.org"
ENV TMPDIR="/home/builder/tmp"
ENV HOME="/home/builder"
ENV SONAR_SCANNER_HOME="/opt/sonar-scanner"


# Default command
CMD ["/bin/bash"]
