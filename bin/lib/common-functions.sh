#!/usr/bin/env bash

TRACE=${TRACE-""}

# If you are changing this also change the
# version in mix.exs for all the apps in platform_umbrella
export BASE_VERSION="1.8.0"

export REGISTRY="ghcr.io/batteries-included"

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

safe_colors() {
    NOFORMAT=${NOFORMAT:-''} RED=${RED:-''} GREEN=${GREEN:-''} ORANGE=${ORANGE:-''} BLUE=${BLUE:-} PURPLE=${PURPLE:-''} CYAN=${CYAN:-''} YELLOW=${YELLOW:-''}
}

setup_trace() {
    # set TRACE if GHA debug logging is enabled
    [[ ${RUNNER_DEBUG:-0} -eq 1 ]] && TRACE=1
    if [[ $TRACE -eq 1 ]]; then
        log "${GREEN}Tracing enabled${NOFORMAT}"
        set -x
    fi
}

setup_root() {
    local current_dir
    current_dir=$(pwd)
    # This way we know where the user was when they called the script
    export CURRENT_DIR=${current_dir}
    bi_pushd "$ROOT_DIR"
}

log() {
    echo >&2 -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

maybe_add_to_path() {
    local path="${1}"
    if ! echo "$PATH" | /usr/bin/grep -Eq "(^|:)$path($|:)"; then
        PATH=$path:$PATH
    fi
}

die() {
    local msg=$1
    local code=${2-1}
    log "$msg"
    exit "$code"
}

term_kill() {
    local pid=${1}
    pkill -TERM -P "$pid" &>/dev/null || true
}

bi_pushd() {
    pushd "$1" >/dev/null || die "Error changing directory to $1"
}

bi_popd() {
    popd >/dev/null || die "Error changing directory"
}

try_portforward() {
    local slug=${1:-"dev"}
    local counter=0
    local lock_dir="${ROOT_DIR}/.flock"
    local lock_file="${lock_dir}/portforward.lockfile"

    mkdir -p "${lock_dir}"

    # Loop forever if PORTFORWARD_ENABLED is set to 1
    # Skip the loop if PORTFORWARD_ENABLED is set to 0

    while [ "${PORTFORWARD_ENABLED:-0}" -eq 1 ]; do
        if ! flock -x -n "${lock_file}" "${SCRIPT_DIR}/pg-forward" "${slug}"; then
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

cleanup() {
    local code="$?"
    trap - ERR EXIT
    # We're going to be sending SIGTERM to ourselves
    # Handle it gracefully
    trap 'exit "$code"' SIGINT SIGTERM

    # We can end up in cleanup from a few different places and colors might not be set
    safe_colors

    log "Cleaning up all subprocesses and jobs"

    # send TERM to all of the processes in the current shell's group
    pkill -15 -g $$ &>/dev/null || true
}

in_github_action() {
    [[ "${GITHUB_ACTIONS:-""}" = "true" ]] && return 0
    [[ -n "${GITHUB_JOB:-""}" ]] && return 0
    return 1
}

# delegate to elixir subcommand
run_mix() {
    "${SCRIPT_DIR}/bix-elixir" run "$@"
}

# delegate to go subcommand
run_bi() {
    "${SCRIPT_DIR}/bix-go" run "$@"
}

version_tag() {
    git describe --match="badtagthatnevermatches" --always --dirty
}

version_lte() {
    printf '%s\n' "$1" "$2" | sort -C -V
}

version_lt() {
    ! version_lte "$2" "$1"
}
