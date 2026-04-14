ARG CUDA_VERSION=12.8.1
FROM runpod/base:1.0.3-cuda1281-ubuntu2404
ARG CUDA_VERSION
LABEL cuda.version="${CUDA_VERSION}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# gh CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install --yes --no-install-recommends gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# starship (prompt)
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes

# zoxide (cd alternative) + dust (du alternative)
RUN curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && \
    cp /root/.local/bin/zoxide /usr/local/bin/ && \
    DUST_VERSION=$(curl -sI https://github.com/bootandy/dust/releases/latest | grep -i location | sed 's/.*tag\/v//' | tr -d '\r\n') && \
    wget -qO /tmp/dust.deb "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/du-dust_${DUST_VERSION}-1_amd64.deb" && \
    dpkg -i /tmp/dust.deb && rm /tmp/dust.deb

# Starship config
COPY config/starship.toml /root/.config/starship.toml

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}"

# Shell config: starship + zoxide
RUN echo 'eval "$(starship init bash)"' >> /root/.bashrc && \
    echo 'eval "$(zoxide init bash)"' >> /root/.bashrc

WORKDIR /workspace

# Startup hook (called by RunPod's /start.sh)
COPY config/pre_start.sh /pre_start.sh
RUN chmod +x /pre_start.sh
