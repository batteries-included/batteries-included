#!/usr/bin/env bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"

GATEWAY_SSH_KEY="gateway_ssh"
DEVSERVER_SSH_KEY="devserver_ssh"

gen_wg_key() {
  if [ ! -f ${1} ]; then
    wg genkey > ${1}
    wg pubkey < ${1} > ${1}.pub
  fi
}

gen_ssh_key() {
  if [ ! -f "${1}" ]; then
    ssh-keygen -t ed25519 -o -f "${1}" -N "" -C "${2}"
  fi
}

pushd "${DIR}/../ops/aws/keys"

gen_ssh_key "${GATEWAY_SSH_KEY}" "gateway"
gen_ssh_key "${DEVSERVER_SSH_KEY}" "devserver"

gen_wg_key "gateway"
gen_wg_key "elliott-desktop"
gen_wg_key "elliott-air"

cp -nv *.pub ../pub_keys/

cat << EOF > ansible_vars.yaml
gateway_private_key: "$(cat gateway)"
gateway_public_key: "$(cat ../pub_keys/gateway.pub)"
EOF

popd
