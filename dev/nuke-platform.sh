#!/usr/bin/env bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

pushd "${DIR}/../platform_umbrella"
rm -rf _build deps .elixir_ls
find . -name node_modules -print0 | xargs -0 rm -rf || true
find . -name assets | grep priv | xargs rm -rf || true
mix deps.get && mix compile --force
popd
