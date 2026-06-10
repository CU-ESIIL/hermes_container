FROM node:24-bookworm-slim

LABEL org.opencontainers.image.title="Hermes"
LABEL org.opencontainers.image.description="ESIIL/OASIS Hermes research appliance with workspace, filesystem, GitHub, and Verde integrations."

ENV HOME=/root
ENV DATA_ROOT=/data
ENV HERMES_HOME=/data/.hermes
ENV HERMES_STATE_DIR=/data/.hermes
ENV HERMES_WORKSPACE=/data/workspace
ENV EXTERNAL_STORAGE_ROOT=/external_storage
ENV HERMES_CMS_PORT=8090
ENV HERMES_PORT=18789
ENV HERMES_HOST=0.0.0.0
ENV WORKSPACE_UI_PORT=8888
ENV HERMES_SEED_WORKSPACE=1
ENV HERMES_INIT_WORKING_GROUP=1
ENV HERMES_BRANDING=1
ENV HERMES_PROJECT_TITLE="OASIS Hermes Working Group"
ENV HERMES_MODEL_PROVIDER=custom
ENV HERMES_INFERENCE_MODEL=js2/gpt-oss-120b
ENV VERDE_LLM_BASE_URL=https://llm-api.cyverse.ai/v1
ENV VERDE_LLM_DEFAULT_MODEL=js2/gpt-oss-120b
ENV VERDE_LLM_PROVIDER_NAME=verde
ARG HERMES_AGENT_BRANCH=main

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

# Install the real Nous Research Hermes Agent runtime.
RUN curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
        | bash -s -- --branch "${HERMES_AGENT_BRANCH}" --skip-setup --skip-browser --hermes-home /data/.hermes \
    && hermes --version \
    && cd /usr/local/lib/hermes-agent \
    && npm install --include=dev \
    && cd /usr/local/lib/hermes-agent/web \
    && npm install --include=dev \
    && npm run build

ENV NODE_ENV=production

COPY requirements-spatiotemporal.txt /tmp/requirements-spatiotemporal.txt
RUN python3 -m pip install --break-system-packages --no-cache-dir \
        jupyterlab \
        playwright \
        uv \
    && python3 -m pip install --break-system-packages --no-cache-dir \
        -r /tmp/requirements-spatiotemporal.txt

WORKDIR /data/workspace

RUN mkdir -p /data/.hermes /data/workspace /workspace /external_storage/local

COPY docker/entrypoint.sh /usr/local/bin/hermes-container-entrypoint
COPY docker/service-entrypoint.sh /usr/local/bin/hermes-service-entrypoint
COPY scripts/init-data-layout.sh /usr/local/bin/hermes-init-data-layout
COPY scripts/openclaw-storage /usr/local/bin/hermes-storage
COPY docker/seed-workspace /opt/hermes/seed-workspace
COPY cms /opt/hermes/cms
COPY storage /opt/hermes/storage
COPY branding/control-ui /opt/hermes/branding/control-ui
COPY docs/assets/brand /opt/hermes/branding/assets
COPY scripts/install-control-ui-branding.sh /usr/local/bin/hermes-install-control-ui-branding
COPY scripts/seed_file_manager_demo.py /usr/local/bin/hermes-seed-file-manager-demo
RUN chmod +x /usr/local/bin/hermes-container-entrypoint \
    && chmod +x /usr/local/bin/hermes-service-entrypoint \
    && chmod +x /usr/local/bin/hermes-init-data-layout \
    && ln -s /usr/local/bin/hermes-storage /usr/local/bin/openclaw-storage \
    && chmod +x /usr/local/bin/hermes-storage \
    && chmod +x /usr/local/bin/hermes-install-control-ui-branding \
    && chmod +x /usr/local/bin/hermes-seed-file-manager-demo \
    && chmod +x /opt/hermes/seed-workspace/scripts/init-working-group.sh \
    && chmod +x /opt/hermes/seed-workspace/scripts/start-pi-liaison.sh \
    && chmod +x /opt/hermes/seed-workspace/scripts/check-secrets.sh \
    && chmod +x /opt/hermes/seed-workspace/scripts/mask-secrets.sh \
    && chmod +x /opt/hermes/cms/hermes_cms.py \
    && chmod +x /opt/hermes/storage/scripts/*.py

VOLUME ["/data", "/workspace", "/external_storage"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/hermes-container-entrypoint"]
CMD ["/bin/bash"]
