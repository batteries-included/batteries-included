#!/usr/bin/env bash

TRACE=${TRACE-""}
BI_BUILD_DIR="${BI_BUILD_DIR:-$HOME/.local/share/bi/dev}"
KEEP_BUILDS="${KEEP_BUILDS:-10}"

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
    local current_dir
    current_dir=$(pwd)
    # This way we know where the user was when they called the script
    export CURRENT_DIR=${current_dir}
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

build_bi() {
    local revision
    revision=$(bi_revision)

    # This is the directory where we will put the binary
    local bin_dir="${BI_BUILD_DIR}/${revision}"
    mkdir -p "${bin_dir}"

    # This is the path to the binary
    # We still want it to be called bi so help works
    local bin_path
    bin_path=$(bi_bin_location)

    if [[ ! -f "${bin_path}" ]]; then
        log "Building bi: ${BLUE}${revision}${NOFORMAT}"
        bi_pushd "${ROOT_DIR}/bi"
        SECONDS=0
        CGO_ENABLED=0 go build \
            -tags "netgo osusergo static_build" \
            -o "${bin_path}" bi
        bi_popd
        log "Built bi in ${RED}${SECONDS}${NOFORMAT} seconds"
    fi

}

clean_bi_build() {
    if [[ ! -d "${BI_BUILD_DIR}" ]]; then
        # No build directory, nothing to clean
        return
    fi

    bi_pushd "${BI_BUILD_DIR}"

    # shellcheck disable=SC2012
    ls -t1 | tail -n "+${KEEP_BUILDS}" | xargs -I {} rm -rf {}
    bi_popd
}

run_bi() {
    local bin_path
    bin_path=$(bi_bin_location)

    # go run on mac is really slow sometimes
    # probably because we are linking in every go
    # file that google engineers got promoted to write
    #
    # So instead we build the binary once per git commit
    # and assume that it is good enough for the duration of the
    # git commit.
    #
    # In addition our AWS kubernetes needs to go through a VPN
    # and get aws credentials that all is piped through bi
    # and referenced in the yaml file for kube. So we want the
    # path to be stable and reliable.
    build_bi

    "${bin_path}" "$@"
}

bi_bin_location() {
    local revision
    revision=$(bi_revision)
    echo "${BI_BUILD_DIR}/${revision}/bi"
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

bi_revision() {
    git rev-parse HEAD:bi
}

bi_pushd() {
    pushd "$1" >/dev/null || die "Error changing directory to $1"
}

bi_popd() {
    popd >/dev/null || die "Error changing directory"
}
