#!/usr/bin/env bash
set -exuo pipefail

deleteAllTagged() {
  kubectl get -lbattery/managed=true ${1} |
    awk '{print $1}' |
    xargs kubectl delete ${1} || true
}

deleteAllNamespaced() {
  kubectl get ${1} -lbattery/managed=true --all-namespaces |
    awk '{print $1} {print $2}' |
    grep -ve NAME |
    xargs -L2 bash -c "kubectl delete ${1} -n \$0 \$1" || true
}

deleteCrds() {
  kubectl get crds |
    grep -ve cattle |
    awk '{print $1}' |
    xargs kubectl delete crds || true
}

deleteRBAC() {
  deleteAllTagged clusterrole
  deleteAllTagged clusterrolebinding
  kubectl get clusterrole |
    grep -E '(loki|battery|promtail|istio|metallb)' |
    awk '{print $1}' |
    xargs kubectl delete clusterrole || true
  kubectl get clusterrolebinding |
    grep -E '(loki|battery|promtail|istio|metallb)' |
    awk '{print $1}' |
    xargs kubectl delete clusterrolebinding || true
}

deleteJunk() {
  kubectl delete configmap istio-ca-root-cert || true
}

deleteRBAC
deleteJunk

deleteAllNamespaced knativeservings
deleteAllNamespaced service
deleteAllNamespaced configmap
deleteAllNamespaced secret
deleteAllNamespaced deployment
deleteAllNamespaced pod

sleep 10

deleteAllTagged namespace
deleteCrds
