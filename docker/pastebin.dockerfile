# syntax=docker/dockerfile:1

ARG DEPLOY_IMAGE_NAME=ubuntu
ARG DEPLOY_IMAGE_TAG=noble-20240605
ARG LANG=C.UTF-8

###############################################################################
# OS Dependencies
#
# This is a copy of the OS dependencies from the build image from platform.dockerfile
#
# Ducplication allows us to cache the build images.
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS os-deps

ARG LANG

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt update && \
    apt install -y \
    apt-transport-https \
    ca-certificates \
    cmake \
    curl \
    git \
    gnupg \
    libssl-dev \
    locales \
    nodejs \
    npm \
    software-properties-common \
    unzip \
    wget \
    && locale-gen $LANG

###############################################################################
# Build the assets
# These will be served from /static in the final image

FROM os-deps AS assets

WORKDIR /source

COPY pastebin-go/assets /source/

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci && \
    npm run build

###############################################################################
# Build the Go binary

FROM golang:1.23.6 AS go-build

WORKDIR /source

COPY pastebin-go /source/

RUN go mod download && \
    go build -o pastebin-go

###############################################################################
# The final image

FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS final

ARG LANG

ENV LANG=$LANG \
    LC_ALL=$LANG

WORKDIR /

RUN apt update && \
    apt install -y \
    libssl3 tini ca-certificates locales && \
    locale-gen $LANG

COPY --from=assets /source/dist /static
COPY --from=go-build /source/pastebin-go /usr/bin/pastebin-go

ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/usr/bin/pastebin-go" ]

EXPOSE 8080
