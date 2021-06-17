#!/bin/bash
set -exuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export DOCKER_BUILDKIT=1
REGISTRY_PORT=$(docker port k3d-k3s-default-registry | cut -d: -f2)
TAG=$(git describe --always --dirty --broken)

pushImage() {
  docker push "localhost:${REGISTRY_PORT}/${1}:${2}"
}

pushd ${DIR}/../platform_umbrella
docker build \
  -t battery/control:${TAG} \
  -t localhost:${REGISTRY_PORT}/battery/control:${TAG} \
  .
pushImage "battery/control" "${TAG}"

# docker build --build-arg RELEASE=home_base \
#   -t battery/home:${TAG} \
#   -t localhost:${REGISTRY_PORT}/battery/home:${TAG} \
#   .

# pushImage "battery/home" "${TAG}"
popd
