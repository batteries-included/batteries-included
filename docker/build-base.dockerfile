# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.4
ARG ERLANG_VERSION=27.3.4
ARG UBUNTU_VERSION=noble-20250415.1

ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-ubuntu-${UBUNTU_VERSION}

FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG}

LABEL org.opencontainers.image.source="https://github.com/batteries-included/batteries-included"
LABEL org.opencontainers.image.description="Batteries Included Build env for elixir"

##########################################################################
# Fetch OS build dependencies
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && \
  apt-get install -y \
      --no-install-recommends \
      build-essential \
      ca-certificates \
      git \
      maven \
      nodejs \
      npm \
      openjdk-21-jdk-headless
