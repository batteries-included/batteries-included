[[ -z ${TRACE:-""} ]] || set -x

TEMPDIRS=()

function log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
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
  local install_path=${1:-"static/public/specs/dev.json"}

  local slug
  # If install path is a file then we need to get the slug
  # from the file
  if [[ -f ${install_path} ]]; then
    slug=$(bi debug spec-slug "${install_path}")
  else
    # Otherwise we can just stop the install path assuming it's a slug already
    slug=${install_path}
  fi
  bi stop "${slug}"
}

function do_bootstrap() {
  do_start "$@"
  local spec_path summary_path slug

  spec_path=${1:-"static/public/specs/dev.json"}
  slug=$(bi debug spec-slug "${spec_path}")
  summary_path=$(bi debug install-summary-path "${slug}")

  m "do" deps.get, compile, kube.bootstrap "${summary_path}"
  # Start the port forwarder
  do_portforward_controlserver "${slug}"

  # Postgrest should be up create the database and run the migrations
  m setup
  # Add the rows that should be there for what's installed
  m seed.control "${summary_path}"
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
  local install_path
  install_path=${1:-"./static/public/specs/int_test.json"}

  log "Starting integration test: ${install_path}"
  local slug
  slug=$(bi debug spec-slug "${install_path}")

  local summary_path
  do_start "${install_path}"
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

  m "do" ecto.reset, \
    seed.control "${summary_path}"

  m test --trace --warnings-as-errors --slowest 1
}

function try_portforward() {
  local slug=${1:-"dev"}
  while true; do
    if ! flock -x -n "${FLAKE_ROOT}/.nix-lock/portforward.lockfile" \
      bash -c "bi postgres port-forward ${slug} controlserver -n battery-base"; then
      log "Port forward failed, retrying..."
      sleep 1
    fi
  done
}

function do_portforward_controlserver() {
  log "Starting port forwarder"

  try_portforward "$@" &
}

function do_setup_assets() {
  pushd "${1}"
  npm install
  npm run css:deploy:dev
  npm run js:deploy:dev
  popd
}

function do_start() {
  local install_path=${1:-"static/public/specs/dev.json"}

  # shellcheck disable=2046
  bi start \
    $([[ -z ''${TRACE:-""} ]] || echo "-v=debug") \
    "${install_path}" >/dev/null
}
