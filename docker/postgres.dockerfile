ARG BUILD_IMAGE_NAME=ghcr.io/batteries-included/build-base
ARG BUILD_IMAGE_TAG=latest

ARG DEPLOY_IMAGE_NAME=ghcr.io/batteries-included/deploy-base
ARG DEPLOY_IMAGE_TAG=latest


FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}

ARG PG_VERSION=latest
ARG PG_MAJOR

# Download and extract the documentdb repo
#######################################################
FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS download

ARG DOCDB_URL

WORKDIR /source

RUN curl -Lo /tmp/source.tgz "${DOCDB_URL}" \
    && tar xf /tmp/source.tgz -C . --strip-components 1 \
    && rm -rf /tmp/source.tgz


# Build the gateway
#######################################################
FROM ${BUILD_IMAGE_NAME}:${BUILD_IMAGE_TAG} AS gw-build

COPY --from=download /source /source

WORKDIR /source/pg_documentdb_gw

ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH

RUN apt-get update \
    && apt-get install -y \
        --no-install-recommends \
        libssl-dev \
        pkg-config \
        rustup \
    && rustup toolchain install stable --no-self-update
    
RUN OPENSSL_STATIC=1 cargo build --release

# A common image for basic postgres install
####################################################
FROM ${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG} AS pg-base

ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}

RUN apt-get update \
    && apt-get install -y \
        --no-install-recommends \
        curl \
        gnupg

RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f 2)-pgdg main ${PG_MAJOR}" \
    > /etc/apt/sources.list.d/pgdg.list \
    && curl -q -o - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update \
    && apt-get install -y \
      --no-install-recommends \
      postgresql-${PG_MAJOR} \
      postgresql-${PG_MAJOR}-cron \
      postgresql-${PG_MAJOR}-pgvector \
      postgresql-${PG_MAJOR}-postgis-3 \
      postgresql-${PG_MAJOR}-rum


# Build the documentdb extension deb
#################################################
FROM pg-base AS docdb

ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}

ARG DOCDB_VERSION

WORKDIR /source

RUN apt-get update \
    && apt-get install -y \
      --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      debhelper \
      devscripts \
      dpkg-dev \
      git \
      libicu-dev \
      libkrb5-dev \
      libpq-dev \
      locales \
      pkg-config \
      postgresql-server-dev-${PG_MAJOR}

COPY --from=download /source /source
# install dependencies using upstream scripts
RUN export CLEAN_SETUP=1 \
    && export INSTALL_DEPENDENCIES_ROOT=/tmp/install \
    && mkdir -p "$INSTALL_DEPENDENCIES_ROOT" \
    && MAKE_PROGRAM=cmake /source/scripts/install_setup_libbson.sh \
    && /source/scripts/install_setup_pcre2.sh \
    && /source/scripts/install_setup_intel_decimal_math_lib.sh \
    && /source/scripts/install_citus_indent.sh \
    && rm -rf "$INSTALL_DEPENDENCIES_ROOT"

# tests require en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANGUAGE=en_US
ENV LC_COLLATE=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8

# actually build and package the extensions
RUN sed -i "s/POSTGRES_VERSION/${PG_MAJOR}/g" /source/packaging/debian_files/control \
    && sed -i "s/DOCUMENTDB_VERSION/${DOCDB_VERSION}/g" /source/packaging/debian_files/changelog \
    && mkdir -p /source/debian \
    && cp /source/packaging/debian_files/* /source/debian \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && sed -i '/internal/d' Makefile \
    && debuild -us -uc \
    && mkdir -p /output \
    && mv /*.deb /output/documentdb.deb

# This is the final output postgres image
#############################################
FROM pg-base

ARG PG_VERSION
ENV PG_VERSION=${PG_VERSION}
ARG PG_MAJOR
ENV PG_MAJOR=${PG_MAJOR}

ENV PATH=$PATH:/usr/lib/postgresql/$PG_MAJOR/bin

# install postgres and extensions
RUN --mount=from=docdb,src=/output,dst=/output \
    apt-get update \
    && apt-get install -y \
        --no-install-recommends \
        "postgresql-${PG_MAJOR}=${PG_VERSION}*" \
        postgresql-${PG_MAJOR}-pg-failover-slots \
        postgresql-${PG_MAJOR}-pgaudit \
        postgresql-${PG_MAJOR}-pgvector \
        postgresql-${PG_MAJOR}-postgis-3 \
        postgresql-${PG_MAJOR}-rum \
    && dpkg -i /output/documentdb.deb \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/* /var/cache/* /var/log/*

RUN usermod -u 26 postgres
USER 26

LABEL org.opencontainers.image.source="https://github.com/batteries-included/batteries-included"
LABEL org.opencontainers.image.description="Batteries Included Postgresql Build"
