# syntax=docker/dockerfile:experimental
#
# This is almost the same dockerfile as 
# the platform one, but it doens't need npm or js deps stages.

ARG ELIXIR_VERSION=1.17.2
ARG ERLANG_VERSION=27.0
ARG UBUNTU_VERSION=noble-20240605

ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-ubuntu-${UBUNTU_VERSION}

ARG DEPLOY_IMAGE_NAME=ubuntu
ARG DEPLOY_IMAGE_TAG=$UBUNTU_VERSION

ARG MIX_ENV=prod

# Name of app, used for directories
ARG APP_NAME=batteries_included

# OS user that app runs under
ARG APP_USER=battery

# OS group that app runs under
ARG APP_GROUP="$APP_USER"

# Runtime dir
ARG APP_DIR=/app

ARG LANG=C.UTF-8

FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS os-deps

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


FROM os-deps AS deps

ARG LANG
ARG MIX_ENV

WORKDIR /source

COPY platform_umbrella/mix.exs platform_umbrella/mix.exs
COPY platform_umbrella/mix.lock platform_umbrella/mix.lock

COPY platform_umbrella/apps/common_core/mix.exs platform_umbrella/apps/common_core/mix.exs
COPY platform_umbrella/apps/common_ui/mix.exs platform_umbrella/apps/common_ui/mix.exs
COPY platform_umbrella/apps/control_server/mix.exs platform_umbrella/apps/control_server/mix.exs
COPY platform_umbrella/apps/control_server_web/mix.exs platform_umbrella/apps/control_server_web/mix.exs
COPY platform_umbrella/apps/event_center/mix.exs platform_umbrella/apps/event_center/mix.exs
COPY platform_umbrella/apps/home_base/mix.exs platform_umbrella/apps/home_base/mix.exs
COPY platform_umbrella/apps/home_base_web/mix.exs platform_umbrella/apps/home_base_web/mix.exs
COPY platform_umbrella/apps/kube_bootstrap/mix.exs platform_umbrella/apps/kube_bootstrap/mix.exs
COPY platform_umbrella/apps/kube_services/mix.exs platform_umbrella/apps/kube_services/mix.exs

RUN cd platform_umbrella \
    && mix do local.hex --force, local.rebar --force \
    && mix deps.get \
    && mix deps.compile --force --skip-umbrella-children

##########################################################################
# Create release

FROM deps AS release

ARG LANG
ARG MIX_ENV

WORKDIR /source

COPY . /source/

RUN cd /source/platform_umbrella \
    && mix do phx.digest, compile, release kube_bootstrap

FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS deploy

ARG LANG
ARG APP_NAME
ARG APP_USER
ARG APP_GROUP
ARG APP_DIR

ARG MIX_ENV
ARG RELEASE

# Set environment vars used by the app
ENV LANG=$LANG \
    LC_ALL=$LANG \
    HOME=$APP_DIR \
    RELEASE_TMP="/run/$APP_NAME" \
    RELEASE=${RELEASE} \
    PORT=4000


RUN apt update \
    && apt install -y libssl3 tini ca-certificates locales \
    && locale-gen $LANG \
    && apt clean

# Create user and group to run under with specific uid
RUN groupadd --gid 10001 --system "$APP_GROUP" \
    && useradd --uid 10000 --system -g "$APP_GROUP" --home "$HOME" "$APP_USER"

# Create app dirs
RUN mkdir -p "/run/$APP_NAME" \
    && chown -R "$APP_USER:$APP_GROUP" "/run/$APP_NAME/"

USER $APP_USER

WORKDIR /app

COPY --from=release --chown="$APP_USER:$APP_GROUP" "/source/platform_umbrella/_build/$MIX_ENV/rel/${RELEASE}" ./

EXPOSE $PORT

ENTRYPOINT ["/sbin/tini", "--" ]

CMD ["bin/kube_bootstrap", "start"]
