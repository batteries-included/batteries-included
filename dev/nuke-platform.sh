#!/usr/bin/env bash
set -exuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
pushd "${DIR}/../platform_umbrella"
RET=0
rm -rf _build deps .elixir_ls
find . -name assets | grep priv | xargs rm -rf || true
mix deps.get && mix compile --force
popd
