#!/usr/bin/env bash
set -xuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
NODE_MOD_DIR="${DIR}/node_modules/"
BIN_DIR="${NODE_MOD_DIR}.bin"
PRETTIER="${BIN_DIR}/prettier"

installPrettier() {
  pushd "${DIR}"
  # After going to the correct location
  # install everything from the packae.json
  # This contains the prettier package and plugins.
  npm ci
  popd
}

if [ ! -d "${NODE_MOD_DIR}" ]; then
  echo "${NODE_MOD_DIR} does not exist."
  installPrettier
fi

if [ ! -f "${PRETTIER}" ]; then
  echo "${PRETTIER} does not exist."
  installPrettier
fi

pushd "${DIR}/../"
${PRETTIER} . --write
popd
