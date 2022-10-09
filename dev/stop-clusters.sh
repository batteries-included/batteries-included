#!/bin/bash
set -xuo pipefail

kind delete cluster --name battery || true
k3d cluster delete || true
