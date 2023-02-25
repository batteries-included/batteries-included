#!/usr/bin/env bash
set -xuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

error() {
  local parent_lineno
  local message
  local code

  parent_lineno="$1"
  message="$2"
  code="${3:-1}"
  if [[ -n "$message" ]]; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}

trap 'error ${LINENO} Trap:' ERR

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

cliDev() {
  pushd "${DIR}/../cli/src"
  set +e
  cargo run -- dev --forward-postgres
  set -e
  echo "Exited"
  popd
  return 1
}

mixBootstrap() {
  pushd "${DIR}/../platform_umbrella/apps/cli_core"
  retry mix run -e "CLICore.InitialSync.sync"
  popd
}

CREATE_CLUSTER=${CREATE_CLUSTER:-true}
FORWARD_CONTROL_POSTGRES=${FORWARD_CONTROL_POSTGRES:-true}
NUM_SERVERS=${NUM_SERVERS:-3}

PARAMS=""
while (("$#")); do
  case "$1" in
    -c | --create-cluster)
      CREATE_CLUSTER=true
      shift
      ;;
    -d | --dont-create-cluster)
      CREATE_CLUSTER=false
      shift
      ;;
    -D | --dont-forward-control)
      FORWARD_CONTROL_POSTGRES=false
      shift
      ;;
    -S | --num-servers)
      shift
      NUM_SERVERS=${1}
      shift
      ;;
    -*) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"

COMMAND="cargo run -- dev"

if [[ $CREATE_CLUSTER == 'true' ]]; then
  COMMAND="${COMMAND} --create-cluster"
fi

if [ "${FORWARD_CONTROL_POSTGRES}" == "true" ]; then
  COMMAND="${COMMAND} --forward-postgres"
fi

pushd "${DIR}/../cli/src"
set +e
${COMMAND}
set -e
echo "Exited"
popd
return 1

wait
