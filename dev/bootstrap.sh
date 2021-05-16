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
    local max=20
    local delay=30

    while true; do
        "$@" && break || {
            if [[ $n -lt $max ]]; then
                ((n++))
                echo "Failed. $n/$max"
                sleep $delay
            else
                error ${LINENO} "The command has failed after $n attempts."
                return 1
            fi
        }
    done
}

portForward() {
    local target=$1
    local portMap=$2
    local namespace=$3

    if kubectl get ns "${namespace}"; then
        # So this is fun. It seems like
        # `portforward.go:233] lost connection to pod` error messages procede a 0 exit code...
        #
        # So since this is likely something to always run. We assume the exiting is bad.
        # it's a hack for until most of this is self hosted in k8s.
        kubectl port-forward "${target}" ${portMap} -n "$namespace" --address 0.0.0.0 && false
        return $?
    else
        return 0
    fi
}

postgresForward() {
    local cluster=$1
    local port=$2
    local ns=${3:-"battery-db"}
    local pod=$(kubectl get pods -o jsonpath={.items..metadata.name} -n ${ns} -l application=spilo -l battery-cluster-name=${cluster} -l spilo-role=master)
    portForward "pods/${pod}" "${port}:5432" ${ns}
}

resetPasswordEnv() {
    local cluster=$1
    local user=${2:-postgres}
    local password=$(kubectl get secrets -n battery-db ${user}.${cluster}.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)
    echo "export POSTGRES_PASSWORD='${password}'" > ${DIR}/../platform_umbrella/.envrc
}

CREATE_CLUSTER=${CREATE_CLUSTER:-false}
FORWARD_EXTERNAL_POSTGRES=${FORWARD_EXTERNAL_POSTGRES:-false}
FORWARD_HOME_POSTGRES=${FORWARD_HOME_POSTGRES:-false}

PARAMS=""
while (( "$#" )); do
  case "$1" in
    -c|--create-cluster)
      CREATE_CLUSTER=true
      shift
      ;;

    -e|--forward-external)
      FORWARD_EXTERNAL_POSTGRES=true
      shift
      ;;

    -b|--forward-home-base)
      FORWARD_HOME_POSTGRES=true
      shift
      ;;
    -*|--*=) # unsupported flags
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



if [[ $CREATE_CLUSTER == 'true' ]];
then
    # Create the cluster
    k3d cluster create -v /dev/mapper:/dev/mapper || true
fi

# Start the services.
kubectl apply -f "${DIR}/k8s"
# Add the CRD definition
kubectl apply -f "${DIR}/../platform_umbrella/manifest.yaml" || true
# Create the cluster
kubectl apply -f "${DIR}/../platform_umbrella/default_cluster.yaml" || true

if [ $FORWARD_EXTERNAL_POSTGRES == "true" ];
then
    (retry portForward "svc/postgres" "5432:5432" "default") &
fi

if [[ $FORWARD_HOME_POSTGRES == "true" ]];
then
    (retry postgresForward "default-home-base" "5433") &
    resetPasswordEnv "default-home-base"
fi

wait
