#!/usr/bin/env sh

set -eu

INSTALL_SPEC_URL="<%= spec_url %>"
VERSION_TAG="<%= version %>"

BI="bi"
EXT=".tar.gz"
VERSION_LOC="${HOME}/.local/share/bi/${BI}-${VERSION_TAG}"

TMP_DIR="$(mktemp -d)"

trap 'rm -rf "${TMP_DIR}"' INT TERM EXIT

check_bi_version() {
    test -f "${VERSION_LOC}"
}

check_installed() {
    command -v "${1}" >/dev/null 2>&1
}

get_bi_release_url() {
    REPO="batteries-included/batteries-included"
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    fetch "https://api.github.com/repos/${REPO}/releases/tags/${VERSION_TAG}" -o - | grep "browser_download_url.*${OS}_${ARCH}${EXT}" | cut -d '"' -f 4
}

# borrowed heavily from nvm-sh/nvm/install.sh
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
    DOWNLOAD_URL="$1"
    OUTPUT_LOC="$2"

    fetch -L -o "${OUTPUT_LOC}" "${DOWNLOAD_URL}"
}

install_release() {
    SOURCE="$1"
    OUTPUT="$2"
    SYMLINK="$3"

    chmod +x "${SOURCE}"
    mkdir -p "$(dirname "${OUTPUT}")"
    mkdir -p "$(dirname "${SYMLINK}")"
    mv "${SOURCE}" "${OUTPUT}"
    ln -sf "${OUTPUT}" "${SYMLINK}"
}

install_bi() {
    INSTALL_DIR="${HOME}/.local/bin"
    OUTPUT_LOC="${TMP_DIR}/${BI}${EXT}"

    DOWNLOAD_URL=$(get_bi_release_url)

    if [ -z "${DOWNLOAD_URL:-""}" ]; then
        echo "Failed to find the asset for version ${VERSION_TAG}."
        exit 1
    fi

    echo "Downloading ${DOWNLOAD_URL} ..."
    download "$DOWNLOAD_URL" "$OUTPUT_LOC"

    # extract to temp directory
    tar -xf "${OUTPUT_LOC}" -C "${TMP_DIR}"

    install_release "${TMP_DIR}/${BI}" "${VERSION_LOC}" "${INSTALL_DIR}/${BI}"
    echo "${BI} installed successfully to ${INSTALL_DIR}"
}

# install bi if needed first
check_bi_version || install_bi
check_installed "${BI}" || install_bi

if check_installed "${BI}"; then
    :
else
    echo "${BI} not installed correctly..."
    exit 1
fi

# start install

"${BI}" start -v debug "${INSTALL_SPEC_URL}"
