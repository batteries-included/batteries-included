#!/bin/bash
set -exuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
export DOCKER_BUILDKIT=1
TAG=$(git describe --always --dirty --broken)

pushImage() {
  REGISTRY_PORT=$(docker port battery-registry | cut -d: -f2)
  docker push "localhost:${REGISTRY_PORT}/${1}:${2}"
}

pushd ${DIR}/../platform_umbrella
docker build \
  -t battery/control:${TAG} \
  .

docker build --build-arg RELEASE=home_base \
  --build-arg BINARY=bin/home_base \
  -t battery/home:${TAG} \
  .

pushImage "battery/control" "${TAG}"
pushImage "battery/home" "${TAG}"

popd
