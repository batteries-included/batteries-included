#!/bin/bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

cloc --ignore-whitespace \
  --exclude-dir=node_modules,deps,_build,.venv,_next,.next,target,assets,package-lock.json,cover \
  "${DIR}/../"
