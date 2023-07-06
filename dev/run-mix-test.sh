#!/usr/bin/env bash
set -exuo pipefail

# We are testing
export MIX_ENV=test

# Go there.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
pushd "${DIR}/../platform_umbrella"

# Debug printing just in case
env

# Get the deps
mix deps.get
# Then compile everything
mix compile --force --warnings-as-errors
# Then clean the database
mix ecto.reset
# Then run all the tests.
mix test --trace --slowest 10 --cover --export-coverage default --warnings-as-errors
mix test.coverage

popd
