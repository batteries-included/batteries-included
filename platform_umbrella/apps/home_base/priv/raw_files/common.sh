#!/usr/bin/env bash
set -eu

# Overridable variables
BI_VERSION_TAG=${BI_VERSION_TAG:-"<%= version %>"}
BASE_DIR=${BASE_DIR:-"${HOME}/.local"}

# Constants
BI="bi"
EXT=".tar.gz"
REPO="batteries-included/batteries-included"

# Locations
VERSION_LOC="${BASE_DIR}/share/bi/${BI}-${BI_VERSION_TAG}"
INSTALL_DIR="${BASE_DIR}/bin"
TMP_DIR="$(mktemp -d)"

# Host info
OS="$(uname -s)"
ARCH="$(uname -m)"

trap 'rm -rf "${TMP_DIR}"' INT TERM EXIT

log() {
    echo >&2 -e "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

check_bi_version() {
    # If there's a BI_OVERRIDE_LOC, then assume the
    # user knows what they're doing
    #
    # (hey that's me and that's not always true)
    if [ -n "${BI_OVERRIDE_LOC:-""}" ]; then
        return 0
    fi
    test -f "${VERSION_LOC}"
}

check_installed() {
    command -v "${1}" >/dev/null 2>&1
}

get_bi_release_url() {
    fetch "https://api.github.com/repos/${REPO}/releases/tags/${BI_VERSION_TAG}" -o - | grep "browser_download_url.*${OS}_${ARCH}${EXT}" | cut -d '"' -f 4
}

fetch() {
    if check_installed "curl"; then
        curl --fail --compressed --silent "$@"
    elif check_installed "wget"; then
        # Emulate curl with wget
        ARGS=$(printf %s\\n "$*" "$@" 2>/dev/null | sed -e 's/--progress-bar /--progress=bar /' \
            -e 's/--compressed //' \
            -e 's/--fail //' \
            -e 's/-L //' \
            -e 's/-I /--server-response /' \
            -e 's/-s /-q /' \
            -e 's/-sS /-nv /' \
            -e 's/-o /-O /' \
            -e 's/-C - /-c /')
        # shellcheck disable=SC2086
        eval wget --quiet $ARGS
    fi
}

download() {
    local download_url="$1"
    local output_loc="$2"

    fetch -L -o "${output_loc}" "${download_url}"
}

install_release_manual() {
    local source="$1"
    local output="$2"
    local symlink="$3"

    log "Installing ${source} to ${output} and linking to ${symlink} without install command"

    chmod +x "${source}"
    mkdir -p "$(dirname "${output}")"
    mkdir -p "$(dirname "${symlink}")"
    mv "${source}" "${output}"
    ln -sf "${output}" "${symlink}"
}

install_release_automatic() {
    local source="$1"
    local output="$2"
    local symlink="$3"

    log "Installing ${source} to ${output} and linking to ${symlink}"

    install -d "$(dirname "${output}")"
    install -m 755 "${source}" "${output}"

    # Add the symlink in the bin directory
    install -d "$(dirname "${symlink}")"
    ln -sf "${output}" "${symlink}"
}

install_release() {
    if check_installed "install"; then
        install_release_automatic "$@"
    else
        install_release_manual "$@"
    fi
}

install_bi() {
    local output_loc="${TMP_DIR}/${BI}${EXT}"

    download_url=$(get_bi_release_url)

    if [ -z "${download_url:-""}" ]; then
        log "Failed to find the asset for version ${BI_VERSION_TAG}."
        exit 1
    fi

    log "Downloading ${download_url} ..."
    download "$download_url" "$output_loc"

    # extract to temp directory
    tar -xf "${output_loc}" -C "${TMP_DIR}"

    install_release "${TMP_DIR}/${BI}" "${VERSION_LOC}" "${INSTALL_DIR}/${BI}"
    log "${BI} installed successfully to ${INSTALL_DIR}"
    log "Please make sure ${INSTALL_DIR} is in your PATH"
}

if [[ ${TRACE:-0} -eq 1 ]]; then
    log "Tracing enabled"
    set -x
fi
