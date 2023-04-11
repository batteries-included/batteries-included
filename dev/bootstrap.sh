#!/usr/bin/env bash
set -xuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

pushd "${DIR}/../cli"
set +e
cargo run -- dev -vv --platform-dir="${DIR}/../platform_umbrella/"
set -e
echo "Exited"
popd
