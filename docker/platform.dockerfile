# syntax=docker/dockerfile:1
#

ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.1
ARG UBUNTU_VERSION=noble-20240801

ARG BUILD_IMAGE_NAME=hexpm/elixir
ARG BUILD_IMAGE_TAG=${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-ubuntu-${UBUNTU_VERSION}

ARG DEPLOY_IMAGE_NAME=ubuntu
ARG DEPLOY_IMAGE_TAG=$UBUNTU_VERSION

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

ARG LANG=en_US.UTF-8

ARG LANGUAGE=en_US:en

##########################################################################
# Fetch OS build dependencies

FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS os-deps

ARG LANG
ARG LANGUAGE

RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt update && \
  apt install -y \
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
  wget && \
  apt clean

# Set the locale
RUN sed -i '/${LANG}/s/^# //g' /etc/locale.gen && locale-gen ${LANG} && \
  localedef -i en_US -f UTF-8 ${LANG} && \
  update-locale LANG=${LANG} LC_ALL=${LANG}

ENV LANGUAGE=${LANGUAGE} \
  LANG=$LANG \
  LC_ALL=$LANG

##########################################################################
# Fetch app library dependencies

FROM os-deps AS deps

ARG MIX_ENV

ENV MIX_ENV=${MIX_ENV}

WORKDIR /source

# Get Elixir app deps
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
COPY platform_umbrella/apps/verify/mix.exs platform_umbrella/apps/verify/mix.exs

WORKDIR /source/platform_umbrella

RUN mix "do" local.hex --force, local.rebar --force && \
  mix deps.get && \
  mix deps.compile --force --skip-umbrella-children

#########################
## Download and Build the dependencies
## for the control server docker
FROM deps AS control-deps

COPY platform_umbrella/apps/control_server_web/assets/package.json /source/platform_umbrella//apps/control_server_web/assets/package.json
COPY platform_umbrella/apps/control_server_web/assets/package-lock.json /source/platform_umbrella//apps/control_server_web/assets/package-lock.json

WORKDIR /source/platform_umbrella/apps/control_server_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci

##########################################################################
# Build ControlServer assets

FROM control-deps AS control-assets

ARG MIX_ENV

ENV MIX_ENV=${MIX_ENV}

WORKDIR /source

COPY . /source/

WORKDIR /source/platform_umbrella

RUN mix deps.get && \
  cd apps/control_server_web/assets && \
  npm run css:deploy && \
  npm run js:deploy

##########################################################################
# Build HomeBase assets

FROM deps AS home-base-deps

COPY platform_umbrella/apps/home_base_web/assets/package.json /source/platform_umbrella//apps/home_base_web/assets/package.json
COPY platform_umbrella/apps/home_base_web/assets/package-lock.json /source/platform_umbrella//apps/home_base_web/assets/package-lock.json

WORKDIR /source/platform_umbrella/apps/home_base_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci

##########################################################################
# Build HomeBase assets

FROM home-base-deps AS home-base-assets

ARG MIX_ENV

ENV MIX_ENV=${MIX_ENV}

WORKDIR /source

COPY . /source/

RUN cd platform_umbrella && \
  mix deps.get && \
  cd apps/home_base_web/assets && \
  npm run css:deploy && \
  npm run js:deploy

##########################################################################
# Create release

FROM deps AS release

ARG MIX_ENV
ARG RELEASE

ENV MIX_ENV=${MIX_ENV} \
  # Before compiling add the bix binary to the path.
  # It is used in the build process for version info.
  PATH="$PATH:/source/bin"

WORKDIR /source

COPY . /source/

COPY --from=home-base-assets /source/platform_umbrella/apps/home_base_web/priv /source/platform_umbrella/apps/home_base_web/priv
COPY --from=control-assets /source/platform_umbrella/apps/control_server_web/priv /source/platform_umbrella/apps/control_server_web/priv

WORKDIR /source/platform_umbrella 

RUN  mix "do" phx.digest, compile, release "${RELEASE}"

##########################################################################
# Create final image that is deployed
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS final

ARG LANG
ARG LANGUAGE
ARG APP_NAME
ARG APP_USER
ARG APP_GROUP
ARG APP_DIR

ARG MIX_ENV
ARG RELEASE

# Set environment vars used by the app
ENV HOME=$APP_DIR \
  RELEASE_TMP="/run/$APP_NAME" \
  MIX_ENV=${MIX_ENV} \
  RELEASE=${RELEASE} \
  PORT=4000

WORKDIR /app

RUN apt update && \
  apt install -y libssl3 tini ca-certificates locales && \
  apt clean

# Set the locale
RUN sed -i '/${LANG}/s/^# //g' /etc/locale.gen && locale-gen ${LANG} && \
  localedef -i en_US -f UTF-8 ${LANG} && \
  update-locale LANG=${LANG} LC_ALL=${LANG}

ENV LANGUAGE=${LANGUAGE} \
  LANG=$LANG \
  LC_ALL=$LANG


# Create user and group to run under with specific uid
RUN groupadd --gid 10001 --system "$APP_GROUP" && \
  useradd --uid 10000 --system -g "$APP_GROUP" --home "$HOME" "$APP_USER"

# Create app dirs
RUN mkdir -p "/run/$APP_NAME" && \
  chown -R "$APP_USER:$APP_GROUP" "/run/$APP_NAME/"

USER $APP_USER

COPY --from=release --chown="$APP_USER:$APP_GROUP" "/source/platform_umbrella/_build/$MIX_ENV/rel/${RELEASE}" ./

EXPOSE $PORT

ENTRYPOINT ["/usr/bin/tini", "--" ]

CMD ["/app/bin/start"]
