FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="Hermes"
LABEL org.opencontainers.image.description="ESIIL/OASIS Hermes research appliance with workspace, filesystem, GitHub, and Verde integrations."

ENV HOME=/root
ENV DATA_ROOT=/data
ENV HERMES_STATE_DIR=/data/.openclaw
ENV OPENCLAW_CONFIG_DIR=/data/.openclaw
ENV OPENCLAW_AUTH_PROFILE_SECRET_DIR=/data/.openclaw/auth-profile-secrets
ENV OPENCLAW_WORKSPACE=/data/workspace
ENV EXTERNAL_STORAGE_ROOT=/external_storage
ENV HERMES_CMS_PORT=8090
ENV OPENCLAW_DEFAULT_MODEL=codex/gpt-5.5
ENV OPENCLAW_GATEWAY_BIND=lan
ENV OPENCLAW_GATEWAY_PORT=18789
ENV OPENCLAW_CONTROL_ORIGINS=http://127.0.0.1:18789,http://localhost:18789
ENV WORKSPACE_UI_PORT=8888
ENV OPENCLAW_SEED_WORKSPACE=1
ENV OPENCLAW_INIT_WORKING_GROUP=1
ENV OPENCLAW_START_PI_LIAISON=1
ENV OPENCLAW_CONFIGURE_SLACK=1
ENV HERMES_BRANDING=1
ENV HERMES_PROJECT_TITLE="OASIS Hermes Working Group"
ENV NODE_ENV=production
ARG OPENCLAW_VERSION=2026.5.18

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        gdal-bin \
        ghostscript \
        git \
        gh \
        imagemagick \
        jq \
        geos-bin \
        libgeos-dev \
        libspatialindex-dev \
        libreoffice \
        nano \
        pandoc \
        poppler-utils \
        proj-bin \
        python3 \
        python3-pip \
        python3-venv \
        qpdf \
        ripgrep \
        rclone \
        sqlite3 \
        latexmk \
        lmodern \
        texlive-fonts-recommended \
        texlive-latex-base \
        texlive-latex-recommended \
        texlive-xetex \
        tini \
        tmux \
        tree \
        unzip \
        vim-tiny \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Hermes uses the upstream agent gateway runtime implementation.
RUN npm install -g openclaw@${OPENCLAW_VERSION} \
    && npm cache clean --force

COPY requirements-spatiotemporal.txt /tmp/requirements-spatiotemporal.txt
RUN python3 -m pip install --break-system-packages --no-cache-dir \
        jupyterlab \
        playwright \
        uv \
    && python3 -m pip install --break-system-packages --no-cache-dir \
        -r /tmp/requirements-spatiotemporal.txt

WORKDIR /data/workspace

RUN mkdir -p /data/.openclaw/auth-profile-secrets /data/workspace /workspace /external_storage/local

COPY docker/entrypoint.sh /usr/local/bin/hermes-container-entrypoint
COPY docker/service-entrypoint.sh /usr/local/bin/hermes-service-entrypoint
COPY scripts/init-data-layout.sh /usr/local/bin/hermes-init-data-layout
COPY scripts/openclaw-storage /usr/local/bin/openclaw-storage
COPY docker/seed-workspace /opt/openclaw/seed-workspace
COPY cms /opt/hermes/cms
COPY storage /opt/hermes/storage
COPY branding/control-ui /opt/hermes/branding/control-ui
COPY docs/assets/brand /opt/hermes/branding/assets
COPY scripts/install-control-ui-branding.sh /usr/local/bin/hermes-install-control-ui-branding
COPY scripts/seed_file_manager_demo.py /usr/local/bin/hermes-seed-file-manager-demo
RUN chmod +x /usr/local/bin/hermes-container-entrypoint \
    && chmod +x /usr/local/bin/hermes-service-entrypoint \
    && chmod +x /usr/local/bin/hermes-init-data-layout \
    && chmod +x /usr/local/bin/openclaw-storage \
    && chmod +x /usr/local/bin/hermes-install-control-ui-branding \
    && chmod +x /usr/local/bin/hermes-seed-file-manager-demo \
    && chmod +x /opt/openclaw/seed-workspace/scripts/init-working-group.sh \
    && chmod +x /opt/openclaw/seed-workspace/scripts/start-pi-liaison.sh \
    && chmod +x /opt/openclaw/seed-workspace/scripts/check-secrets.sh \
    && chmod +x /opt/openclaw/seed-workspace/scripts/mask-secrets.sh \
    && chmod +x /opt/hermes/cms/hermes_cms.py \
    && chmod +x /opt/hermes/storage/scripts/*.py

VOLUME ["/data", "/workspace", "/external_storage"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/hermes-container-entrypoint"]
CMD ["/bin/bash"]
