#!/bin/bash
set -exuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
export DOCKER_BUILDKIT=1
REGISTRY_PORT=$(docker ps | grep registry | awk '{print $11}' | cut -d: -f2 | cut -d- -f1)
TAG=$(git describe --always --dirty --broken)

pushImage() {
  local image=$1
  local tag=$2
  docker push "localhost:${REGISTRY_PORT}/${image}:${tag}"
}

pushd ${DIR}/../platform_umbrella
docker build \
  -t battery/control:latest \
  -t battery/control:${TAG} \
  -t localhost:${REGISTRY_PORT}/battery/control:latest \
  -t localhost:${REGISTRY_PORT}/battery/control:${TAG} \
  .

docker build --build-arg RELEASE=home_base \
  -t battery/home:latest \
  -t battery/home:${TAG} \
  -t localhost:${REGISTRY_PORT}/battery/home:latest \
  -t localhost:${REGISTRY_PORT}/battery/home:${TAG} \
  .

pushImage "battery/control" "${TAG}"
pushImage "battery/home" "${TAG}"
popd
