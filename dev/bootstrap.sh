#!/bin/bash
set -euo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

set -x
# Grab the location we'll use it for yaml locations soon
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Create the cluster
# kind create cluster --config "${DIR}/kind-config.yaml"
k3d cluster create || true
# Start the services.
kubectl apply -f "${DIR}/k8s"

# sleep some amount of time while waiting. This is horrible.
# Yeah
# so what.
# I'm sure there's a better kubectl way but this is a hack while we can't self host.
sleep 30

kubectl port-forward svc/postgres 5432:5432 --address 0.0.0.0 &
kubectl port-forward svc/grafana 3000:3000 -n monitoring --address 0.0.0.0 &
wait
