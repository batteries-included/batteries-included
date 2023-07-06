#!/usr/bin/env bash
set -exuo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

DEV=${1}
DEST=${2:-"$HOME/coding_challenges/$DEV"}
CHALLENGE=${3:-whats_up}

createDest() {
  rm -rf ${DEST}
  mkdir -p ${DEST}
  cp -r ${DIR}/../coding_challenges/${CHALLENGE} ${DEST}/
}

cleanChallenge() {
  rm -rf .elixir_ls/ .vscode/ deps/ _build/
  rm -rf whats_up*.db*
}
initGit() {
  git init .
  git add .
  git commit -am "feat: add the barebones whats_up challenge for ${DEV}"
}
createTar() {
  local tar_name
  tar_name=${CHALLENGE}.tar.gz
  tar czf ${tar_name} ${CHALLENGE}
  sha256sum -b ${tar_name} >SHA256SUMS
  rm -rf ${CHALLENGE}
}

createDest

pushd ${DEST}

pushd ${CHALLENGE}
cleanChallenge
initGit
popd

createTar
popd
