# syntax=docker/dockerfile:1

ARG BASE_IMAGE_NAME=ghcr.io/batteries-included/build-base
ARG BASE_IMAGE_TAG=latest

ARG DEPLOY_IMAGE_NAME=ghcr.io/batteries-included/deploy-base
ARG DEPLOY_IMAGE_TAG=latest

ARG LANG=C.UTF-8

###############################################################################
# Build the assets
# These will be served from /static in the final image

FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS assets

WORKDIR /source

COPY pastebin-go/assets /source/

RUN npm --prefer-offline --no-audit --progress=false --loglevel=error ci && \
    npm run build

###############################################################################
# Build the Go binary

FROM golang:1.24.2 AS go-build

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

COPY --from=assets /source/dist /static
COPY --from=go-build /source/pastebin-go /usr/bin/pastebin-go

ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/usr/bin/pastebin-go" ]

EXPOSE 8080
