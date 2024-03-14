[[ -z ${TRACE:-""} ]] || set -x

trap 'trap - SIGTERM && kill -- -$$' SIGINT SIGTERM EXIT

function bootstrap_bcli() {
  # shellcheck disable=2046
  bcli dev \
    $([[ -z ''${TRACE:-""} ]] || echo "-vv") \
    --platform-dir=platform_umbrella \
    "$@"
  echo "Exited"
}
