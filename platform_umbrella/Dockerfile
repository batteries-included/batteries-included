# syntax=docker/dockerfile:experimental
#
# Build app
#
# It takes advantage of caching and parallel build support in BuildKit.
#
# The "syntax" line must be the first thing in the file, as it enables the
# new syntax for caching, etc. see
# https://docs.docker.com/develop/develop-images/build_enhancements/
# https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md

ARG ELIXIR_VERSION=1.14.1
ARG ERLANG_VERSION=25.1.2
ARG ALPINE_VERSION=3.16.2

ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}

ARG DEPLOY_IMAGE_NAME=alpine
ARG DEPLOY_IMAGE_TAG=$ALPINE_VERSION

# Docker registry for base images, default is docker.io
# If specified, should have a trailing slash
ARG REGISTRY=""

# Elixir release env to build
ARG MIX_ENV=prod

# This should match the mix.exs releases map
ARG RELEASE=control_server

# Name of app, used for directories
ARG APP_NAME=batteries_included

# OS user that app runs under
ARG APP_USER=battery

# OS group that app runs under
ARG APP_GROUP="$APP_USER"

# Runtime dir
ARG APP_DIR=/app

ARG LANG=C.UTF-8

ARG BINARY=bin/control_server

##########################################################################
# Fetch OS build dependencies

FROM ${REGISTRY}${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS os-deps

ARG LANG

RUN apk update \
  && apk add --no-cache --update \
    alpine-sdk \
    git \
    ca-certificates \
    build-base \
    make \
    g++ \
    wget \
    curl \
    inotify-tools \
    nodejs \
    npm \
  && npm install npm -g --no-progress \
  && update-ca-certificates --fresh \
  && rm -rf /var/cache/apk/*

##########################################################################
# Fetch app library dependencies

FROM os-deps AS deps

ARG LANG
ARG MIX_ENV

WORKDIR /app

# Get Elixir app deps
COPY mix.exs .
COPY mix.lock .

COPY apps/cli/mix.exs apps/cli/mix.exs
COPY apps/cli_core/mix.exs apps/cli_core/mix.exs
COPY apps/common_testing/mix.exs apps/common_testing/mix.exs
COPY apps/common_ui/mix.exs apps/common_ui/mix.exs
COPY apps/control_server/mix.exs apps/control_server/mix.exs
COPY apps/control_server_web/mix.exs apps/control_server_web/mix.exs
COPY apps/event_center/mix.exs apps/event_center/mix.exs
COPY apps/home_base/mix.exs apps/home_base/mix.exs
COPY apps/home_base_web/mix.exs apps/home_base_web/mix.exs
COPY apps/kube_ext/mix.exs apps/kube_ext/mix.exs
COPY apps/kube_resources/mix.exs apps/kube_resources/mix.exs
COPY apps/kube_services/mix.exs apps/kube_services/mix.exs

RUN mix do local.hex --force, local.rebar --force \
  && mix deps.get \
  && mix deps.compile --force --skip-umbrella-children

#########################
## Download and Build the dependencies
## for the control server docker
FROM deps AS control-deps

ARG LANG
ARG MIX_ENV

COPY apps/control_server_web/assets/package.json /app/apps/control_server_web/assets/package.json
COPY apps/control_server_web/assets/package-lock.json /app/apps/control_server_web/assets/package-lock.json

WORKDIR /app/apps/control_server_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci

##########################################################################
# Build ControlServer assets

FROM control-deps AS control-assets

ARG LANG
ARG MIX_ENV

WORKDIR /app

# Yes we are over copying. That's because tailwind requires purging
# from known used css classes. That requires that the source code is
# in place for webpack to build css and js.... yeah.
# So while it would be great to make this more cache friendly. We likely can't.
COPY apps /app/apps
COPY config /app/config

RUN mix deps.get \
  && mix esbuild.install \
  && cd /app/apps/control_server_web \
  && ls -al ../../deps/ \
  && mix setup \
  && mix assets.deploy

##########################################################################
# Build HomeBase assets

FROM deps AS home-base-deps

ARG LANG
ARG MIX_ENV

COPY apps/home_base_web/assets/package.json /app/apps/home_base_web/assets/package.json
COPY apps/home_base_web/assets/package-lock.json /app/apps/home_base_web/assets/package-lock.json

WORKDIR /app/apps/home_base_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci

##########################################################################
# Build HomeBase assets

FROM home-base-deps AS home-base-assets

ARG LANG
ARG MIX_ENV

WORKDIR /app

COPY apps /app/apps
COPY config /app/config

RUN mix deps.get \
  && mix esbuild.install \
  && cd /app/apps/home_base_web \
  && ls -al ../../deps/ \
  && mix setup \
  && mix assets.deploy

##########################################################################
# Create release

FROM deps AS release

ARG LANG
ARG MIX_ENV
ARG RELEASE

WORKDIR /app

COPY apps ./apps
COPY config ./config
COPY rel ./rel

COPY --from=home-base-assets /app/apps/home_base_web/priv ./apps/home_base_web/priv
COPY --from=control-assets /app/apps/control_server_web/priv ./apps/control_server_web/priv

RUN mix do phx.digest, compile --force, release "${RELEASE}"

##########################################################################
# Create final image that is deployed
FROM ${REGISTRY}${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS deploy

ARG LANG
ARG APP_NAME
ARG APP_USER
ARG APP_GROUP
ARG APP_DIR

ARG MIX_ENV
ARG RELEASE
ARG BINARY

# Set environment vars used by the app
ENV LANG=$LANG \
  HOME=$APP_DIR \
  RELEASE_TMP="/run/$APP_NAME" \
  RELEASE=${RELEASE} \
  BINARY=${BINARY} \
  PORT=4000

RUN apk update \
  && apk add --no-cache --update \
    bash \
    ca-certificates \
    tini \
    libstdc++ \
    libgcc \
    bind-tools \
    openssl \
    ncurses-libs \
  && update-ca-certificates --fresh \
  && rm -rf /var/cache/apk/*

# Create user and group to run under with specific uid
RUN addgroup -g 10001 -S "$APP_GROUP" \
  && adduser -u 10000 -S "$APP_USER" -G "$APP_GROUP" -h "$HOME"

# Create app dirs
RUN mkdir -p "/run/$APP_NAME" \
  && chown -R "$APP_USER:$APP_GROUP" "/run/$APP_NAME/"

USER $APP_USER

WORKDIR $APP_DIR

COPY --from=release --chown="$APP_USER:$APP_GROUP" "/app/_build/$MIX_ENV/rel/${RELEASE}" ./

EXPOSE $PORT

ENTRYPOINT ["/sbin/tini", "--" ]

CMD ["${BINARY}", "start"]
