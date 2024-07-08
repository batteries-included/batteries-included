# syntax=docker/dockerfile:experimental

ARG DEPLOY_IMAGE_NAME=ubuntu
ARG DEPLOY_IMAGE_TAG=noble-20240605

###############################################################################
# OS Dependencies
#
# This is a copy of the OS dependencies from the build image from platform.dockerfile
# 
# Ducplication allows us to cache the build images.
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS os-deps

ARG LANG

RUN apt update && \
    apt install -y \
    build-essential \
    nodejs \
    npm \
    curl \
    wget \
    git \
    cmake \
    libssl-dev \
    pkg-config \
    autoconf \
    m4 \
    libncurses5-dev \
    unzip \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    locales \
    && locale-gen $LANG \
    && apt clean

###############################################################################
# Build the assets
# These will be served from /static in the final image

FROM os-deps as assets

WORKDIR  /source

COPY pastebin-go/assets /source/

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci \
    && npm run build

###############################################################################
# Build the Go binary

FROM golang:1.22.4 as go-build

WORKDIR  /source

COPY pastebin-go /source/

RUN go mod download \
    && go build -o pastebin-go


###############################################################################
# The final image

FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} as final

COPY --from=assets /source/dist /static
COPY --from=go-build /source/pastebin-go /bin/pastebin-go

EXPOSE 8080

RUN apt update && apt install -y tini \
    && apt clean

WORKDIR /

ENTRYPOINT [ "/sbin/tini", "--" ]

CMD [ "/bin/pastebin-go" ]
