#!/bin/bash
set -xuo pipefail

if command -v kind; then
  kind delete cluster --name battery || true
fi

if command -v k3d; then
  k3d cluster delete || true
fi
