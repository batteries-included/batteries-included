[[ -z ${TRACE:-""} ]] || set -x

PIDS=()
TEMPDIRS=()

function cleanup() {
  for pid in "${PIDS[@]}"; do
    kill -9 "$pid" >/dev/null 2>&1 || true
  done
  for tempdir in "${TEMPDIRS[@]}"; do
    rm -rf "$tempdir" || true
  done
}

trap cleanup EXIT SIGINT SIGTERM

function do_stop() {
  # TODO this should take an install spec
  # and conditionally stop the right things
  bi kind stop
}

function do_bootstrap() {
  local install_path=${1:-"static/public/specs/dev.json"}
  local summary_path

  summary_path=$(mktemp -d)
  TEMPDIRS+=("$summary_path")
  # shellcheck disable=2046
  bi start \
    $([[ -z ''${TRACE:-""} ]] || echo "-v=debug") \
    -S "${summary_path}/summary.json" \
    "${install_path}"
  m "do" deps.get, compile, kube.bootstrap "${summary_path}/summary.json"

  # Start the port forwarder
  portforward_controlserver

  # Postgrest should be up create the database and run the migrations
  m setup
  # Add the rows that should be there for what's installed
  m seed.control "${summary_path}/summary.json"
  echo "Exited"
}

function try_portforward() {
  while true; do
    flock -x -n .nix-lock/portforward.lockfile -c "bi postgres port-forward controlserver -n battery-base"
    sleep 1
  done
}

function portforward_controlserver() {
  try_portforward &
  local pid=$!

  # Add the pid to the list of PIDS
  PIDS+=("$pid")
}
