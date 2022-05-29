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

trap 'error ${LINENO} Trap:' ERR
trap 'trap - SIGTERM && kill -- -$$' SIGINT SIGTERM EXIT

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
          echo "Failed. ${n}/${max}local code
  local end
  local runtime"
          sleep $delay
        fi
      else
        error ${LINENO} "The command has failed after ${n} attempts."
      fi
    }
  done
}

portForward() {
  local target
  local portMap
  local namespace

  target=$1
  portMap=$2
  namespace=$3

  if kubectl get ns "${namespace}"; then

    set +e
    kubectl port-forward "${target}" "${portMap}" -n "${namespace}" --address 0.0.0.0
    local code=$?
    set -e
    echo "Exited"
    return 1
  else
    return 0
  fi
}

postgresForward() {
  local cluster
  local port
  local ns
  local pod

  cluster=$1
  port=$2
  ns=${3:-"battery-core"}
  pod=$(kubectl \
    get pods \
    -o jsonpath={.items..metadata.name} \
    -n "${ns}" \
    -l "application=spilo,battery-pg-cluster=${cluster},spilo-role=master")
  portForward "pods/${pod}" "${port}:5432" "${ns}"
}

buildLocalControl() {
  bash "${DIR}/build_local.sh"
}

cargoBootstrap() {
  pushd "${DIR}/../rust_utils"
  cargo run -- bootstrap || true
  popd
}

mixBootstrap() {
  pushd "${DIR}/../platform_umbrella/apps/bootstrap"
  mix run -e "Bootstrap.run()"
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
    -b | --forward-home-base)
      FORWARD_HOME_POSTGRES=true
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
    -* | --*=) # unsupported flags
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
  # Create the cluster
  k3d cluster create -v /dev/mapper:/dev/mapper \
    --k3s-arg '--disable=traefik@server:*' \
    --registry-create battery-registry \
    --wait \
    -s "${NUM_SERVERS}" \
    -p "8081:80@loadbalancer" || true
fi

if [ "${BUILD_CONTROL_SERVER}" == "true" ]; then
  buildLocalControl
fi

cargoBootstrap
mixBootstrap

if [ "${FORWARD_CONTROL_POSTGRES}" == "true" ]; then
  (retry postgresForward "pg-control" "5432") &
fi

if [[ "${FORWARD_HOME_POSTGRES}" == "true" ]]; then
  (retry postgresForward "default-home-base" "5433") &
fi

wait
