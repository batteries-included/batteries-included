#!/usr/bin/env bash
set -exuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
pushd "${DIR}/../platform_umbrella"
RET=0
MIX_ENV=prod mix do clean, compile, release cli --overwrite
popd
