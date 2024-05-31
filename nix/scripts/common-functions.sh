[[ -z ${TRACE:-""} ]] || set -x

TEMPDIRS=()

function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

function cleanup() {
  for tempdir in "${TEMPDIRS[@]}"; do
    rm -rf "$tempdir" || true
  done

  for pid in $(pgrep -P $$); do
    # This is kind of a kludge to get around sending
    # a signal to the forked off bash, flock,
    # and bi which is portforwarding
    for child in $(pgrep -P "$pid"); do
      log "Killing child $child"
      pkill -P "$child" >/dev/null 2>&1 || true
      kill "$child" >/dev/null 2>&1 || true
    done

    pkill -P "$pid" >/dev/null 2>&1 || true
    kill "$pid" >/dev/null 2>&1 || true
  done

  local jobs
  jobs=$(jobs -pr)

  for job in $jobs; do
    log "Killing job $job"
    kill "$job" >/dev/null 2>&1 || true
  done

  pkill -P $$ || true
}

trap cleanup EXIT SIGINT SIGTERM

function do_stop() {
  local spec_path=${1:-"bootstrap/dev.spec.json"}

  local slug
  # If install path is a file then we need to get the slug
  # from the file
  if [[ -f ${spec_path} ]]; then
    slug=$(bi debug spec-slug "${spec_path}")
  else
    # Otherwise we can just stop the install path assuming it's a slug already
    slug=${spec_path}
  fi
  bi stop "${slug}"
}

function do_bootstrap() {
  do_start "$@"
  local spec_path summary_path slug
  spec_path=${1:-"bootstrap/dev.spec.json"}
  slug=$(bi debug spec-slug "${spec_path}")
  summary_path=$(bi debug install-summary-path "${slug}")

  # bootstrap_path is the full absolute path to the folder containing the spec file
  bootstrap_path=$(get_abs_filename "$(dirname "${spec_path}")")

  m "do" deps.get, compile, kube.bootstrap "${summary_path}"
  # Start the port forwarder
  do_portforward_controlserver "${slug}"

  # Postgres should be up create the database and run the migrations
  m setup
  # Add the rows that should be there for what's installed
  m "do" seed.control "${summary_path}", \
    seed.home "${bootstrap_path}"
  echo "Exited"
}

function whats_running() {
  log "Checking what's running"

  log "Battery Base"
  kubectl get pods -n battery-base -o yaml

  log "Battery Core"
  kubectl get pods -n battery-core -o yaml
}

function do_integration_test_deep() {
  localspec_path
  spec_path=${1:-"./bootstrap/integration-test.spec.json"}

  log "Starting integration test: ${spec_path}"
  local slug
  slug=$(bi debug spec-slug "${spec_path}")

  local summary_path
  do_start "${spec_path}"
  summary_path=$(bi debug install-summary-path "${slug}")

  m "do" deps.get, compile, kube.bootstrap "${summary_path}"

  do_portforward_controlserver "${slug}"

  do_integration_test "${summary_path}"

  do_stop "${slug}"
}

function do_integration_test() {
  log "starting integration test"
  summary_path=${1:-""}

  if [[ -z ${summary_path} ]]; then
    log "No summary path provided"
    summary_path=$(bi debug install-summary-path "integration-test")
  fi

  export MIX_ENV=integration
  # Get the deps and compile everything
  # This makes sure to compile
  # before ecto.reset does (which wouldn't
  # compile all protocols and leave the _build
  # in a bad state)
  m "do" \
    deps.get, \
    compile --warnings-as-errors

  do_setup_assets platform_umbrella/apps/control_server_web/assets
  do_setup_assets platform_umbrella/apps/home_base_web/assets

  bootstrap_path=$(get_abs_filename "bootstrap")

  m "do" ecto.reset, \
    seed.control "${summary_path}", \
    seed.home "${bootstrap_path}"

  m test --trace --warnings-as-errors --slowest 1
}

function try_portforward() {
  local slug=${1:-"dev"}
  local counter=0
  while true; do
    if ! flock -x -n "${FLAKE_ROOT}/.nix-lock/portforward.lockfile" \
      bash -c "bi postgres port-forward ${slug} controlserver -n battery-base"; then
      log "Port forward failed, retrying..."
      counter=$((counter + 1))

      local sleep_time
      if [[ $((counter * 2)) -gt 20 ]]; then
        sleep_time=20
      else
        sleep_time=$((counter * 2))
      fi
      sleep "${sleep_time}"
    fi
  done
}

function do_portforward_controlserver() {
  log "Starting port forwarder"

  try_portforward "$@" &
}

function do_setup_assets() {
  pushd "${1}" || fail "setting up assets"
  npm install
  npm run css:deploy:dev
  npm run js:deploy:dev
  popd || fail "setting up assets"
}

function do_start() {
  local spec_path=${1:-"bootstrap/dev.spec.json"}

  # shellcheck disable=2046
  bi start \
    $([[ -z ''${TRACE:-""} ]] || echo "-v=debug") \
    "${spec_path}" >/dev/null
}

function fail() {
  log "Failed: $1"
  exit 1
}
