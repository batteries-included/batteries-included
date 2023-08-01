#!/usr/bin/env bash
set -xuo pipefail

# Grab the location we'll use it for lots later on
#
# We fully expand it as well so that rust chdir works when calling into mix
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

trap 'trap - SIGTERM && kill -- -$$' SIGINT SIGTERM EXIT

pushd "${DIR}/../cli"
set +e
cargo run -- dev -vv --platform-dir="${DIR}/../platform_umbrella/"
set -e
echo "Exited"
popd
