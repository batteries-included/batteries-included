#!/bin/bash
set -xuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

BIN_DIR="${DIR}/node_modules/.bin/"

pushd "${DIR}/../"
${BIN_DIR}/prettier . --write
popd
