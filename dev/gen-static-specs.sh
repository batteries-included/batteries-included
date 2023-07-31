#!/usr/bin/env bash
set -exuo pipefail

DIR="${BASH_SOURCE%/*}"

pushd "${DIR}/../platform_umbrella"
mix "do" clean, compile --force
mix gen.static.installations "${DIR}/../cli/tests/resources/specs"
mix gen.static.installations "${DIR}/../static/public/specs"
popd
