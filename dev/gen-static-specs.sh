#!/usr/bin/env bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

pushd "${DIR}/../platform_umbrella"
mix compile
mix gen.static.installations "${DIR}/../cli/tests/resources/specs"
mix gen.static.installations "${DIR}/../static/public/specs"
popd
