# syntax=docker/dockerfile:1

#
# The container image used as the final image that we use to deploy
#

ARG UBUNTU_VERSION=noble-20250127
ARG LANGUAGE=en_US:en
ARG LANG=en_US.UTF-8

# Create deploy base image
FROM ubuntu:${UBUNTU_VERSION}

ARG LANGUAGE
ARG LANG

RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    locales \
    tini

# Set the locale
RUN sed -i "/${LANG}/s/^# //g" /etc/locale.gen && \
  locale-gen "${LANG}" && \
  localedef -i en_US -f UTF-8 "${LANG}" && \
  update-locale "LANG=${LANG}" "LC_ALL=${LANG}"

ENV LANGUAGE=${LANGUAGE} \
  LANG=${LANG} \
  LC_ALL=${LANG}
