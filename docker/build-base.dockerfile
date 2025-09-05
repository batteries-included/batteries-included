# syntax=docker/dockerfile:1

ARG UBUNTU_VERSION=use_version_from_tool-versions
ARG ELIXIR_VERSION=use_version_from_tool-versions
ARG ERLANG_VERSION=use_version_from_tool-versions


ARG BASE_IMAGE_NAME=hexpm/elixir
ARG BASE_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-ubuntu-${UBUNTU_VERSION}

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

LABEL org.opencontainers.image.source="https://github.com/batteries-included/batteries-included"
LABEL org.opencontainers.image.description="Batteries Included Build env for elixir"

ENV DEBIAN_FRONTEND=noninteractive

##########################################################################
# Fetch OS build dependencies
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && \
  apt-get install -y \
      --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      git \
      maven \
      nodejs \
      npm \
      openjdk-21-jdk-headless
