ARG KC_VERSION=latest

ARG BASE_IMAGE_NAME=ghcr.io/batteries-included/build-base
ARG BASE_IMAGE_TAG=latest

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS theme-builder

WORKDIR /keycloak-theme
COPY keycloak-theme/ /keycloak-theme/
RUN --mount=type=cache,target=/root/.npm \
    npm --prefer-offline --no-audit --progress=false --loglevel=error ci && \
    npm run build && \
    npm run build-keycloak-theme

FROM quay.io/keycloak/keycloak:${KC_VERSION} AS builder

ARG KC_DB=postgres
ARG KC_FEATURES=preview
ARG KC_HEALTH_ENABLED=true
ARG KC_METRICS_ENABLED=true
ARG KC_HTTP_RELATIVE_PATH=/

ENV KC_DB=${KC_DB}
ENV KC_FEATURES=${KC_FEATURES}
ENV KC_HEALTH_ENABLED=${KC_HEALTH_ENABLED}
ENV KC_METRICS_ENABLED=${KC_METRICS_ENABLED}
ENV KC_HTTP_RELATIVE_PATH=${KC_HTTP_RELATIVE_PATH}

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KC_VERSION}

ARG JAR_NAME=keycloak-theme-for-kc-all-other-versions.jar

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --from=theme-builder /keycloak-theme/dist_keycloak/${JAR_NAME} /opt/keycloak/providers
