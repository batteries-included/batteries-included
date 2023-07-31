#!/usr/bin/env bash
set -exuo pipefail

DIR="${BASH_SOURCE%/*}"

pushd "${DIR}/../ops/aws/ansible"
ansible-playbook -i inventory.yml all.yml -b
popd
