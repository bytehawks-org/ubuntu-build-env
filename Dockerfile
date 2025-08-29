# Dockerfile per ambiente di sviluppo completo
# Base: Ubuntu LTS per compatibilità packaging .deb
FROM ubuntu:24.04

# Evita prompt interattivi durante l'installazione
ENV DEBIAN_FRONTEND=noninteractive

# Aggiorna il sistema e installa dipendenze base
RUN apt-get update && apt-get install -y \
    # Strumenti di compilazione C/C++
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Parser generators e strumenti di analisi lessicale
    bison \
    flex \
    byacc \
    # Strumenti aggiuntivi per build complesse
    ninja-build \
    meson \
    # Librerie di sviluppo comuni
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libgdbm-dev \
    libc6-dev \
    libnss3-dev \
    # Strumenti per packaging Debian
    debhelper \
    dh-make \
    devscripts \
    fakeroot \
    lintian \
    quilt \
    dpkg-dev \
    # Utility generali
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
    # Strumenti per virtualizzazione
    qemu-utils \
    # AWS CLI dependencies
    python3 \
    python3-pip \
    # GitLab CI/CD tools
    openssh-client \
    rsync \
    ca-certificates \
    gnupg \
    lsb-release \
    bash \
    # Container tools per GitLab
    apt-transport-https \
    software-properties-common \
    # Pulizia cache
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installa AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

# Installa Packer
ARG PACKER_VERSION=1.14.1
RUN wget -O packer.zip "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
    && unzip -o packer.zip -d /opt/packer \
    && chmod +x /opt/packer/packer \
    && ln -s /opt/packer/packer /usr/local/bin/packer \
    && rm packer.zip

# Installa Terraform (spesso usato insieme a Packer)
ARG TERRAFORM_VERSION=1.13.1
RUN wget -O terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip -o terraform.zip -d /opt/terraform \
    && chmod +x /opt/terraform/terraform \
    && ln -s /opt/terraform/terraform /usr/local/bin/terraform \
    && rm terraform.zip 

# Installa Docker CLI per GitLab CI (Docker-in-Docker scenarios)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installa GitLab CLI (glab)
RUN curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_linux_amd64.tar.gz | tar -xz -C /tmp \
    && mv /tmp/bin/glab /usr/local/bin/glab \
    && chmod +x /usr/local/bin/glab

# Installa strumenti per testing e quality gates
RUN pip3 install --no-cache-dir \
    pytest \
    pytest-cov \
    black \
    flake8 \
    bandit \
    safety \
    pre-commit \
    semgrep

# Installa SonarScanner CLI
ARG SONAR_SCANNER_VERSION=7.2.0.5079
RUN wget -O sonar-scanner.zip "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip" \
    && unzip sonar-scanner.zip -d /opt \
    && mv /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux /opt/sonar-scanner \
    && rm sonar-scanner.zip \
    && ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner

# Installa Trivy (vulnerability scanner)
RUN wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy-archive-keyring.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install -y trivy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installa Grype (vulnerability scanner alternativo)
RUN curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Installa Syft (SBOM generator)
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Installa PMD (static analysis per Java/PHP/altri linguaggi)
ARG PMD_VERSION=7.16.0
RUN wget -O pmd.zip "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-dist-${PMD_VERSION}-bin.zip" \
    && unzip pmd.zip -d /opt \
    && mv /opt/pmd-bin-${PMD_VERSION} /opt/pmd \
    && rm pmd.zip \
    && ln -s /opt/pmd/bin/pmd /usr/local/bin/pmd

# Installa Hadolint (Dockerfile linter)
ARG HADOLINT_VERSION=v2.12.0
RUN wget -O /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint

# Installa OSV-Scanner (Open Source Vulnerability scanner)
RUN curl -L https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64 -o /usr/local/bin/osv-scanner \
    && chmod +x /usr/local/bin/osv-scanner

# Installa CodeQL CLI (GitHub's semantic code analysis)
ARG CODEQL_VERSION=2.22.4
RUN wget -O codeql.zip "https://github.com/github/codeql-cli-binaries/releases/download/v${CODEQL_VERSION}/codeql-linux64.zip" \
    && unzip codeql.zip -d /opt \
    && rm codeql.zip \
    && ln -s /opt/codeql/codeql /usr/local/bin/codeql

# Crea directory di lavoro
#WORKDIR /workspace

# Variabili d'ambiente per il packaging
#ENV DEBFULLNAME="Bytehawks GitHub developer"
#ENV DEBEMAIL="developer@bytehawks.org"

# Variabili d'ambiente per gli strumenti di analisi
#ENV SONAR_SCANNER_HOME="/opt/sonar-scanner"
#ENV PATH="${SONAR_SCANNER_HOME}/bin:${PATH}"

# Crea utente dedicato per le build
RUN groupadd -r builder && useradd -r -g builder -m -s /bin/bash builder \
    # Aggiunge builder ai gruppi necessari
    && usermod -a -G sudo builder \
    # Configura sudo senza password per builder
    && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    # Crea directory per build temporanee
    && mkdir -p /home/builder/{workspace,tmp,build} \
    && chown -R builder:builder /home/builder \
    # Configura fakeroot per l'utente builder
    && mkdir -p /home/builder/.fakeroot \
    && chown -R builder:builder /home/builder/.fakeroot

# Installa Rust per l'utente builder
USER builder
WORKDIR /home/builder

# Installa Rust tramite rustup per l'utente builder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && echo 'source ~/.cargo/env' >> ~/.bashrc

# Aggiunge Rust al PATH per l'utente builder
ENV PATH="/home/builder/.cargo/bin:${PATH}"

# Installa i componenti Rust per l'utente builder
RUN ~/.cargo/bin/rustup component add \
    rustfmt \
    clippy \
    rust-src \
    && ~/.cargo/bin/cargo install cargo-deb

# Configura Git per l'utente builder
RUN git config --global user.name "Builder User" \
    && git config --global user.email "builder@localhost" \
    && git config --global init.defaultBranch main

# Variabili d'ambiente per l'utente builder
ENV DEBFULLNAME="Bytehawks GitHub developer"
ENV DEBEMAIL="developer@bytehawks.org"
ENV TMPDIR="/home/builder/tmp"
ENV HOME="/home/builder"
ENV SONAR_SCANNER_HOME="/opt/sonar-scanner"
ENV PATH="${SONAR_SCANNER_HOME}/bin:${PATH}"

# Comando predefinito
CMD ["/bin/bash"]
