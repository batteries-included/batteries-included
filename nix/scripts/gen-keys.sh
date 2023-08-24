# shellcheck disable=2164

[[ -z ${TRACE:-""} ]] || set -x

GATEWAY_SSH_KEY="gateway_ssh"
DEVSERVER_SSH_KEY="devserver_ssh"

gen_wg_key() {
  if [ ! -f "${1}" ]; then
    wg genkey >"${1}"
    wg pubkey <"${1}" >"${1}".pub
  fi
}

gen_ssh_key() {
  if [ ! -f "${1}" ]; then
    ssh-keygen -t ed25519 -o -f "${1}" -N "" -C "${2}"
  fi
}

pushd "ops/aws/keys" &>/dev/null
trap 'popd &> /dev/null' EXIT

gen_ssh_key "${GATEWAY_SSH_KEY}" "gateway"
gen_ssh_key "${DEVSERVER_SSH_KEY}" "devserver"

# iterate over lines in ops/aws/keys/keys-to-generate
# if you need to add a key, that's the place to do it
while read -r line; do
  # TODO(jdt): trim trailing comments
  trimmed="$(echo "$line" | tr -d '[:space:]')"
  [[ -z $trimmed ]] && continue
  [[ $trimmed =~ ^#.* ]] && continue
  gen_wg_key "$trimmed"
done <keys-to-generate

cp -nv ./*.pub ../pub_keys/

cat <<EOF >ansible_vars.yaml
gateway_private_key: "$(cat gateway)"
gateway_public_key: "$(cat ../pub_keys/gateway.pub)"
EOF
