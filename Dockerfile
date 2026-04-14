ARG CUDA_VERSION=12.8.1
FROM runpod/base:1.0.3-cuda1281-ubuntu2404
ARG CUDA_VERSION
LABEL cuda.version="${CUDA_VERSION}"

ARG STARSHIP_VERSION=1.24.2
ARG ZOXIDE_VERSION=0.9.9
ARG DUST_VERSION=1.2.4
ARG JUST_VERSION=1.49.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# gh CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -sSfLo /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install --yes --no-install-recommends gh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# starship (prompt)
RUN curl -sSfL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin/

# zoxide (cd alternative) + dust (du alternative) + just (command runner)
RUN curl -sSfL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
      | tar xz -C /usr/local/bin/ && \
    curl -sSfLo /tmp/dust.deb "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/du-dust_${DUST_VERSION}-1_amd64.deb" && \
    dpkg -i /tmp/dust.deb && rm /tmp/dust.deb && \
    curl -sSfL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
      | tar xz -C /usr/local/bin/ just

# Starship config
COPY config/starship.toml /root/.config/starship.toml

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}"

# uv: default to CUDA 12.8 PyTorch wheels (for uv pip interface)
ENV UV_TORCH_BACKEND=cu128

# Shell config: starship + zoxide
RUN echo 'eval "$(starship init bash)"' >> /root/.bashrc && \
    echo 'eval "$(zoxide init bash)"' >> /root/.bashrc

WORKDIR /workspace

# Startup hook (called by RunPod's /start.sh)
COPY config/pre_start.sh /pre_start.sh
RUN chmod +x /pre_start.sh
