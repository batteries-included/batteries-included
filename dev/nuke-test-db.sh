#!/usr/bin/env bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

pushd "${DIR}/../platform_umbrella"
mix compile --force
export MIX_ENV=test
mix do compile --force, ecto.reset
popd
