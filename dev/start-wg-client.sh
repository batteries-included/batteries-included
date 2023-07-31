#!/usr/bin/env bash
set -exuo pipefail

DIR="${BASH_SOURCE%/*}"

wg-quick down wg0 || true
"${DIR}/gen-wireguard-client-config.sh" "${1}" | tee /etc/wireguard/wg0.conf
wg-quick up wg0
