FROM docker.io/library/node:20-slim

ARG SANDBOX_NAME="gemini-cli-sandbox"
ARG CLI_VERSION_ARG
ENV SANDBOX="$SANDBOX_NAME"
ENV CLI_VERSION=$CLI_VERSION_ARG

# The following packages have been removed to reduce image size:
# - make, g++: build-time dependencies, not needed at runtime.
# - man-db, less: for viewing man pages, not needed in a container.
#
# install minimal set of packages, set up npm global folder, then clean up
# This is done in a single RUN command to reduce the number of layers.
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 \
  curl \
  dnsutils \
  jq \
  bc \
  gh \
  git \
  unzip \
  rsync \
  ripgrep \
  procps \
  psmisc \
  lsof \
  socat \
  ca-certificates \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /usr/local/share/npm-global \
  && chown -R node:node /usr/local/share/npm-global

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# switch to non-root user node
USER node

# install gemini-cli and clean up
# Using CLI_VERSION_ARG to make the build reproducible by avoiding wildcards.
COPY packages/cli/dist/google-gemini-cli-${CLI_VERSION_ARG}.tgz /usr/local/share/npm-global/gemini-cli.tgz
COPY packages/core/dist/google-gemini-cli-core-${CLI_VERSION_ARG}.tgz /usr/local/share/npm-global/gemini-core.tgz
RUN npm install -g /usr/local/share/npm-global/gemini-cli.tgz /usr/local/share/npm-global/gemini-core.tgz \
  && npm cache clean --force \
  && rm -f /usr/local/share/npm-global/gemini-{cli,core}.tgz

# default entrypoint when none specified
CMD ["gemini"]
