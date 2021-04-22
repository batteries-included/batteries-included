#!/bin/bash
set -xuo pipefail

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
    local service=$1
    local portMap=$2
    local namespace=$3

    if kubectl get ns "${namespace}"; then
        # So this is fun. It seems like
        # `portforward.go:233] lost connection to pod` error messages procede a 0 exit code...
        #
        # So since this is likely something to always run. We assume the exiting is bad.
        # it's a hack for until most of this is self hosted in k8s.
        kubectl port-forward "${service}" ${portMap} -n "$namespace" --address 0.0.0.0 && false
        return $?
    else
        return 0
    fi
}

set -x
# Grab the location we'll use it for yaml locations soon
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# Create the cluster
k3d cluster create -v /dev/mapper:/dev/mapper || true
# Start the services.
kubectl apply -f "${DIR}/k8s"
# Add the CRD definition
kubectl apply -f "${DIR}/../control_server_umbrella/manifest.yaml"
# Create the cluster
kubectl apply -f "${DIR}/../control_server_umbrella/default_cluster.yaml"

# sleep some amount of time while waiting. This is horrible.
# Yeah
# so what.
# I'm sure there's a better kubectl way but this is a hack while we can't self host.
(retry portForward "svc/postgres" "5432:5432" "default") &
(retry portForward "svc/grafana" "3000:3000" "monitoring") &
wait
