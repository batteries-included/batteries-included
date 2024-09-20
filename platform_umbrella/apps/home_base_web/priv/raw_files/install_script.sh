#!/usr/bin/env sh

set -eux

BI="bi"
TMP_DIR="$(mktemp -d)"

INSTALL_SPEC_URL="<%= spec_url %>"

trap 'rm -rf "${TMP_DIR}"' INT TERM EXIT

check_installed() {
    command -v "${1}" >/dev/null 2>&1
}

install_bi() {
    REPO="batteries-included/batteries-included"
    INSTALL_DIR="$HOME/.local/bin"
    OS="$(uname -s)"
    ARCH="$(uname -m)"
    EXT=".tar.gz"
    OUTPUT_LOC="${TMP_DIR}/${BI}${EXT}"

    VERSION=$(curl --silent "https://api.github.com/repos/${REPO}/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    DOWNLOAD_URL=$(curl --silent "https://api.github.com/repos/${REPO}/releases/tags/${VERSION}" | grep "browser_download_url.*${OS}_${ARCH}${EXT}" | cut -d '"' -f 4)

    if [ -z "${DOWNLOAD_URL}" ]; then
        echo "Failed to find the asset for version ${VERSION}."
        exit 1
    fi

    echo "Downloading ${DOWNLOAD_URL} ..."
    curl -L -o "${OUTPUT_LOC}" "${DOWNLOAD_URL}"

    # extract to temp directory
    if [ "$EXT" = ".tar.gz" ]; then
        tar -xf "${OUTPUT_LOC}" -C "${TMP_DIR}"
    elif [ "$EXT" = ".zip" ]; then
        unzip "${OUTPUT_LOC}" -d "${TMP_DIR}"
    fi

    chmod +x "${TMP_DIR}/${BI}"
    mv "${TMP_DIR}/${BI}" "${INSTALL_DIR}/${BI}"
    echo "${BI} installed successfully to ${INSTALL_DIR}"
}

# install bi if needed first
if check_installed "${BI}"; then
    echo "${BI} already installed..."
else
    install_bi
    if check_installed "${BI}"; then
        :
    else
        echo "${BI} not installed correctly..."
        exit 1
    fi
fi

# start install

"${BI}" start -v debug "${INSTALL_SPEC_URL}"
