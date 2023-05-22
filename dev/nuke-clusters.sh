#!/usr/bin/env bash
set -xuo pipefail

deleteK3dCluster() {
  if command -v k3d; then
    k3d cluster delete || true
  fi
}

deleteKindCluster() {
  if command -v kind; then
    kind delete cluster --name ${1} || true
  fi
}

deleteKindCluster "battery"
deleteKindCluster "batteries"
deleteK3dCluster
