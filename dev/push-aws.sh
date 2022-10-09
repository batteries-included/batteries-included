#!/bin/bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

pushd "${DIR}/../ops/aws/ansible"
ansible-playbook -i inventory.yml all.yml -b
popd
