#!/bin/bash
set -exuo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
KEYS_DIR="${DIR}/../ops/aws/keys"
TERRAFORM_DIR="${DIR}/../ops/aws/terraform"
CLIENT_NAME=${1:-wireguard-client}
CLIENT_KEY=$(cat ${KEYS_DIR}/${CLIENT_NAME})
SERVER_PUBKEY=$(cat ${KEYS_DIR}/gateway.pub)
OUTPUT_NAME="gateway_public_ip"
GATEWAY_IP=$(terraform -chdir=${TERRAFORM_DIR} output -raw $OUTPUT_NAME)

cat << END
[Interface]
PrivateKey = ${CLIENT_KEY}
Address = 10.250.0.1/32

[Peer]
PublicKey = $SERVER_PUBKEY
AllowedIPs = 10.250.0.0/24, 10.0.0.0/16
Endpoint = $GATEWAY_IP:51820
END
