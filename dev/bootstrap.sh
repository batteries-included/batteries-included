#!/bin/bash
set -xuo pipefail

# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

error() {
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]]; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  exit "${code}"
}

trap 'error ${LINENO} Trap:' ERR
trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

retry() {
  local n=1
  local max=10
  local delay=30

  while true; do
    "$@" && break || {
      local code=$?
      if [[ $n -lt $max ]]; then

        # timeout replaces the exit code with 124 according to the man page
        # Lets exploit that.
        # Explicitly treat timeouts as not failures.
        # Then in portForward() we timeout just before the idle time. (5 min/300s)
        if [[ $code -eq 124 ]]; then
          echo "Looks command timed out. Not counting it"
        else
          ((n++))
          echo "Failed. $n/$max"
        sleep $delay
        fi
      else
        error ${LINENO} "The command has failed after $n attempts."
      fi
    }
  done
}

portForward() {
  local target=$1
  local portMap=$2
  local namespace=$3

  if kubectl get ns "${namespace}"; then

    set +e
    timeout 280s kubectl port-forward "${target}" ${portMap} -n "$namespace" --address 0.0.0.0
    local code=$?
    set -e
    echo "Exited"
    return ${code}
  else
    return 0
  fi
}

postgresForward() {
  local cluster=$1
  local port=$2
  local ns=${3:-"battery-db"}
  local pod=$(kubectl \
            get pods \
            -o jsonpath={.items..metadata.name} \
            -n ${ns} -l application=spilo \
            -l battery-cluster-name=${cluster} \
            -l spilo-role=master)
  portForward "pods/${pod}" "${port}:5432" ${ns}
}

resetPasswordEnv() {
  local cluster=$1
  local user=${2:-postgres}
  local password=$(kubectl 
        get secrets \
        -n battery-db ${user}.${cluster}.credentials.postgresql.acid.zalan.do \
        -o 'jsonpath={.data.password}' | base64 -d)
  echo "export POSTGRES_PASSWORD='${password}'" >${DIR}/../platform_umbrella/.envrc
}

buildLocalControl() {
  ${DIR}/build_local.sh
}

CREATE_CLUSTER=${CREATE_CLUSTER:-false}
FORWARD_EXTERNAL_POSTGRES=${FORWARD_EXTERNAL_POSTGRES:-false}
FORWARD_HOME_POSTGRES=${FORWARD_HOME_POSTGRES:-false}
BUILD_CONTROL_SERVER=${BUILD_CONTROL_SERVER:-false}

PARAMS=""
while (("$#")); do
  case "$1" in
  -c | --create-cluster)
    CREATE_CLUSTER=true
    shift
    ;;

  -e | --forward-external)
    FORWARD_EXTERNAL_POSTGRES=true
    shift
    ;;

  -b | --forward-home-base)
    FORWARD_HOME_POSTGRES=true
    shift
    ;;
  -B | --build-local)
    BUILD_CONTROL_SERVER=true
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
  k3d cluster create -v /dev/mapper:/dev/mapper --registry-create || true
fi

# Start the services.
kubectl apply -f "${DIR}/k8s"
# Add the CRD definition
kubectl apply -f "${DIR}/../platform_umbrella/manifest.yaml" || true
# Create the cluster
kubectl apply -f "${DIR}/../platform_umbrella/default_cluster.yaml" || true

if [ $BUILD_CONTROL_SERVER == "true" ]; then
  buildLocalControl
fi

if [ $FORWARD_EXTERNAL_POSTGRES == "true" ]; then
  (retry portForward "svc/postgres" "5432:5432" "default") &
fi

if [[ $FORWARD_HOME_POSTGRES == "true" ]]; then
  (retry postgresForward "default-home-base" "5433") &
  resetPasswordEnv "default-home-base"
fi

wait
