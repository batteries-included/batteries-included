#!/usr/bin/env bash
set -exuo pipefail

DIR="${BASH_SOURCE%/*}"
KEYS_DIR="${DIR}/../ops/aws/keys"
CLIENT_NAME=${1:-wireguard-client}
CLIENT_KEY=$(cat "${KEYS_DIR}/${CLIENT_NAME}")
SERVER_PUBKEY=$(cat "${KEYS_DIR}/gateway.pub")

cat <<END
[Interface]
PrivateKey = ${CLIENT_KEY}
Address = 10.250.0.1/32

[Peer]
PublicKey = $SERVER_PUBKEY
AllowedIPs = 10.250.0.0/24, 10.0.0.0/16
Endpoint = pub-wg.batteriesincl.com:51820
END
