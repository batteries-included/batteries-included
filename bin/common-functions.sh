#!/usr/bin/env bash
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
    if [[ $TRACE -eq 1 ]]; then
        log "${GREEN}Tracing enabled${NOFORMAT}"
        set -x
    fi
}

setup_root() {
    log "Entering root directory: ${CYAN}$ROOT_DIR${NOFORMAT}"
    bi_pushd "$ROOT_DIR"
}

log() {
    echo >&2 -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

die() {
    local msg=$1
    local code=${2-1}
    log "$msg"
    exit "$code"
}

term_kill() {
    local pid=${1}
    pkill -TERM -P "$pid" >/dev/null 2>&1 || true
}

run_bi() {
    bi_pushd "${ROOT_DIR}/bi"
    go run bi "$@"
}

run_mix() {
    bi_pushd "${ROOT_DIR}/platform_umbrella"
    mix "$@"
    bi_popd
}

## From an install spec file get the slug
get_slug() {
    local input=${1:-"bootstrap/dev.spec.json"}
    if [[ -f ${input} ]]; then
        input=$(realpath "${input}")
        run_bi debug spec-slug "${input}"
    else
        echo "${input}"
    fi
}

get_summary_path() {
    local slug=${1}
    log "Getting summary path for ${BLUE}${slug}${NOFORMAT}"
    run_bi debug install-summary-path "$slug"
}

version_tag() {
    git describe --match="badtagthatnevermatches" --always --dirty
}

bi_pushd() {
    pushd "$1" >/dev/null || die "Error changing directory to $1"
}

bi_popd() {
    popd >/dev/null || die "Error changing directory"
}
