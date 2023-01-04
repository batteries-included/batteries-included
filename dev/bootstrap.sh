#!/bin/bash
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

killSpawned() {
  # process group inheritance doesn't play nice with long running System.cmd's from elixir, so specifically kill the
  # kubectl port-forward by using lsof (present on Mac OS and available across all linuces) and then kill all
  # process-group members
  kill -- $(lsof -t -i :5432) -$$
}

trap 'error ${LINENO} Trap:' ERR

trap "trap - SIGTERM && killSpawned" SIGINT SIGTERM EXIT

retry() {
  local n
  local max
  local delay
  local start
  local code
  local end
  local runtime

  n=1
  max=10
  delay=30
  start=$(date +%s)

  while true; do
    start=$(date +%s)
    "$@" && break || {
      code=$?
      end=$(date +%s)
      runtime=$((end - start))
      if [[ $n -lt $max ]]; then
        # Explicitly treat timeouts as not failures.
        if [[ $runtime -gt 200 ]]; then
          echo "Looks command timed out. Not counting it"
        else
          ((n++))
          echo "Failed. ${n}/${max}"
          sleep $delay
        fi
      else
        error ${LINENO} "The command has failed after ${n} attempts."
      fi
    }
  done
}

kindCluster() {
  pushd "${DIR}/../platform_umbrella/apps/cli_core"
  mix run -e "CLICore.KindCluster.kind_cluster"
  popd
}

postgresForwardControl() {
  pushd "${DIR}/../platform_umbrella/apps/cli_core"
  set +e
  mix run -e "CLICore.Kubectl.postgres_forward_control"
  set -e
  echo "Exited"
  popd
  return 1
}

buildLocalControl() {
  bash "${DIR}/build-local.sh"
}

mixBootstrap() {
  pushd "${DIR}/../platform_umbrella/apps/cli_core"
  retry mix run -e "CLICore.InitialSync.sync"
  popd
}

CREATE_CLUSTER=${CREATE_CLUSTER:-true}
FORWARD_CONTROL_POSTGRES=${FORWARD_CONTROL_POSTGRES:-true}
FORWARD_HOME_POSTGRES=${FORWARD_HOME_POSTGRES:-false}
BUILD_CONTROL_SERVER=${BUILD_CONTROL_SERVER:-false}
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
    -B | --build-local)
      BUILD_CONTROL_SERVER=true
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

if [[ $CREATE_CLUSTER == 'true' ]]; then
  kindCluster
fi

if [ "${BUILD_CONTROL_SERVER}" == "true" ]; then
  buildLocalControl
fi

mixBootstrap

if [ "${FORWARD_CONTROL_POSTGRES}" == "true" ]; then
  (retry postgresForwardControl) &
fi

wait
