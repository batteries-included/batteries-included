# syntax=docker/dockerfile:1.7-labs

ARG BASE_IMAGE_NAME=ghcr.io/batteries-included/build-base
ARG BASE_IMAGE_TAG=latest

ARG DEPLOY_IMAGE_NAME=ghcr.io/batteries-included/deploy-base
ARG DEPLOY_IMAGE_TAG=latest

ARG MIX_ENV=prod

ARG IMAGE_DESCRIPTION="Batteries Included Platform Service"

##########################################################################
# Set up base mix / elixir build container

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS deps

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

WORKDIR /source/platform_umbrella

# Get Elixir app deps
COPY platform_umbrella/mix.exs mix.exs
COPY platform_umbrella/mix.lock mix.lock
COPY --parents platform_umbrella/apps/*/mix.exs /source/

RUN mix "do" \
  local.hex --force, \
  local.rebar --force, \
  deps.get --only "${MIX_ENV}"

##########################################################################
# Build control server assets

FROM deps AS control-server-assets

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

COPY --from=deps /source/platform_umbrella/deps  /source/platform_umbrella/deps
COPY platform_umbrella/apps/common_ui /source/platform_umbrella/apps/common_ui
COPY platform_umbrella/apps/control_server_web/lib /source/platform_umbrella/apps/control_server_web/lib
COPY platform_umbrella/apps/control_server_web/assets /source/platform_umbrella/apps/control_server_web/assets
COPY platform_umbrella/apps/home_base_web/lib /source/platform_umbrella/apps/home_base_web/lib
COPY platform_umbrella/apps/home_base_web/assets /source/platform_umbrella/apps/home_base_web/assets

WORKDIR /source/platform_umbrella/apps/control_server_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci && \
  npm run css:deploy && \
  npm run js:deploy


##########################################################################
# Build home base assets

FROM deps AS home-base-assets

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

COPY --from=deps /source/platform_umbrella/deps  /source/platform_umbrella/deps
COPY platform_umbrella/apps/common_ui /source/platform_umbrella/apps/common_ui
COPY platform_umbrella/apps/control_server_web/lib /source/platform_umbrella/apps/control_server_web/lib
COPY platform_umbrella/apps/control_server_web/assets /source/platform_umbrella/apps/control_server_web/assets
COPY platform_umbrella/apps/home_base_web/lib /source/platform_umbrella/apps/home_base_web/lib
COPY platform_umbrella/apps/home_base_web/assets /source/platform_umbrella/apps/home_base_web/assets

WORKDIR /source/platform_umbrella/apps/home_base_web/assets

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci && \
  npm run css:deploy && \
  npm run js:deploy


##########################################################################
# Compile

FROM deps AS compile

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

ARG BI_RELEASE_HASH
ENV BI_RELEASE_HASH=${BI_RELEASE_HASH}

COPY . /source/

COPY --from=home-base-assets \
  /source/platform_umbrella/apps/home_base_web/priv \
  /source/platform_umbrella/apps/home_base_web/priv

COPY --from=control-server-assets \
  /source/platform_umbrella/apps/control_server_web/priv \
  /source/platform_umbrella/apps/control_server_web/priv

WORKDIR /source/platform_umbrella

# Force a recompile everything
# Even remove deps that are from this umbrella
# They shouldn't be there but just in case
SHELL ["/bin/bash", "-c"]
RUN <<EOF
rm -rf _build deps/{common_core,common_ui,control_server,control_server_web,event_center,home_base,home_base_web,kube_bootstrap,kube_services,verify} 
mix "do" clean, deps.get --only "${MIX_ENV}", phx.digest, compile --force
EOF

##########################################################################
# Create release

FROM compile AS release

ARG MIX_ENV
ENV MIX_ENV=${MIX_ENV}

ARG RELEASE

RUN mix release "${RELEASE}"

##########################################################################
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}

# Container metadata
ARG IMAGE_DESCRIPTION
LABEL org.opencontainers.image.source="https://github.com/batteries-included/batteries-included"
LABEL org.opencontainers.image.description="${IMAGE_DESCRIPTION}"

# Name of app, used for directories
ARG APP_NAME=batteries_included

# OS user that app runs under
ARG APP_USER=battery

# OS group that app runs under
ARG APP_GROUP="$APP_USER"

# Runtime dir
ARG APP_DIR=/app

ARG MIX_ENV
ARG RELEASE

# Set environment vars used by the app
ENV HOME=$APP_DIR \
  RELEASE_TMP="/run/$APP_NAME" \
  MIX_ENV=${MIX_ENV} \
  RELEASE=${RELEASE} \
  PORT=4000

WORKDIR /app

# Create user and group to run under with specific uid
RUN groupadd --gid 10000 --system "$APP_GROUP" && \
  useradd --uid 10000 --system -g "$APP_GROUP" --home "$HOME" "$APP_USER"

# Create app dirs
RUN mkdir -p "/run/$APP_NAME" && \
  chown -R "$APP_USER:$APP_GROUP" "/run/$APP_NAME/"

USER $APP_USER

COPY --from=release --chown="$APP_USER:$APP_GROUP" \
  "/source/platform_umbrella/_build/${MIX_ENV}/rel/${RELEASE}" \
  ./

EXPOSE $PORT

ENTRYPOINT ["/usr/bin/tini", "--" ]

CMD ["/app/bin/start"]
