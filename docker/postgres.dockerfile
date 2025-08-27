ARG BASE_IMAGE_NAME=ghcr.io/batteries-included/build-base
ARG BASE_IMAGE_TAG=latest

ARG DEPLOY_IMAGE_NAME=ghcr.io/batteries-included/deploy-base
ARG DEPLOY_IMAGE_TAG=latest


FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}

ARG PG_VERSION=latest
ARG PG_MAJOR

ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

RUN apt-get update \
    && apt-get install -y \
        --no-install-recommends \
        gnupg \
        postgresql-common \
    && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y -c "${PG_MAJOR}" \
    && apt-get install -y \
        --no-install-recommends \
        -o Dpkg::::="--force-confdef" \
        -o Dpkg::::="--force-confold" \
        postgresql-common \
    && sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
    && apt-get install -y \
        --no-install-recommends \
        -o Dpkg::::="--force-confdef" \
        -o Dpkg::::="--force-confold" \
        "postgresql-${PG_MAJOR}=${PG_VERSION}*" \
        postgresql-${PG_MAJOR}-pg-failover-slots \
        postgresql-${PG_MAJOR}-pgaudit \
        postgresql-${PG_MAJOR}-pgvector \
        postgresql-${PG_MAJOR}-postgis \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

RUN usermod -u 26 postgres
USER 26

LABEL org.opencontainers.image.source="https://github.com/batteries-included/batteries-included"
LABEL org.opencontainers.image.description="Batteries Included Postgresql Build"
