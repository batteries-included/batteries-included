#!/usr/bin/env bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

wg-quick down wg0 || true
${DIR}/wireguard-client-config.sh "${1}" | tee /etc/wireguard/wg0.conf
wg-quick up wg0
