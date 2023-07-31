#!/usr/bin/env bash
set -exuo pipefail

DIR="${BASH_SOURCE%/*}"

pushd "${DIR}/../platform_umbrella"
mix compile --force
export MIX_ENV=test
mix "do" compile --force, ecto.reset
popd
