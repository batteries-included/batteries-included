# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.18.3
ARG ERLANG_VERSION=27.3.2
ARG UBUNTU_VERSION=noble-20250127

ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-ubuntu-${UBUNTU_VERSION}

##########################################################################
# Fetch OS build dependencies

FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG}
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && \
  apt-get install -y \
    --no-install-recommends \
      apt-transport-https \
      autoconf \
      build-essential \
      ca-certificates \
      cmake \
      curl \
      git \
      gnupg \
      libncurses5-dev \
      libssl-dev \
      locales \
      m4 \
      nodejs \
      npm \
      pkg-config \
      software-properties-common \
      unzip \
      wget
