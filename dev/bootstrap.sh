#!/usr/bin/env bash
set -xuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

error() {
  local parent_lineno
  local message
  local code

  parent_lineno="$1"
  message="$2"
  code="${3:-1}"
  if [[ -n $message ]]; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}

trap 'error ${LINENO} Trap:' ERR
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

pushd "${DIR}/../cli"
set +e
cargo run -- dev -vvv --platform-dir="${DIR}/../platform_umbrella/"
set -e
echo "Exited"
popd
return 1

wait
