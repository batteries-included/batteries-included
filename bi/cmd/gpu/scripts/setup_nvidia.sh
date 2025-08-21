#!/usr/bin/env bash

set -Eeuo pipefail
#
# This script automates the setup of the NVIDIA Container Toolkit for use with Kind.
# It is designed to be idempotent and can be run multiple times safely.
#
# It performs the following actions:
# 1. Installs the NVIDIA Container Toolkit.
# 2. Configures the Docker daemon to use the NVIDIA runtime.
# 3. Configures the NVIDIA container runtime for Kind compatibility.
# 4. Restarts the Docker daemon to apply changes.
#

# --- Helper Functions ---

# log <message>
log() {
    echo "➡️  $1"
}

# error <message>
error() {
    echo "❌ $1" >&2
    exit 1
}

# check_root
# Ensures the script is run as root, as most commands require sudo.
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "This script must be run as root. Please use sudo."
    fi
}

# --- Installation Functions ---

# install_toolkit_debian
# Installs nvidia-container-toolkit on Debian-based systems (Ubuntu, Debian).
install_toolkit_debian() {
    log "Configuring NVIDIA Container Toolkit repository for Debian/Ubuntu..."
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

    log "Updating package list and installing nvidia-container-toolkit..."
    apt-get update
    apt-get install -y nvidia-container-toolkit
}

# install_toolkit_rhel
# Installs nvidia-container-toolkit on RHEL-based systems (CentOS, Fedora, Amazon Linux).
install_toolkit_rhel() {
    log "Configuring NVIDIA Container Toolkit repository for RHEL/Fedora..."
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo |
        tee /etc/yum.repos.d/nvidia-container-toolkit.repo >/dev/null

    log "Installing nvidia-container-toolkit..."
    # Use dnf if available, otherwise fall back to yum
    if command -v dnf &>/dev/null; then
        dnf install -y nvidia-container-toolkit
    else
        yum install -y nvidia-container-toolkit
    fi
}

# install_toolkit_suse
# Installs nvidia-container-toolkit on SUSE-based systems (OpenSUSE, SLES).
install_toolkit_suse() {
    log "Configuring NVIDIA Container Toolkit repository for SUSE..."
    zypper ar https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo

    log "Installing nvidia-container-toolkit..."
    zypper --gpg-auto-import-keys install -y nvidia-container-toolkit
}

# --- Configuration Functions ---

# configure_nvidia_runtime
# Configures Docker to use the NVIDIA runtime and enables volume mounts for Kind.
configure_nvidia_runtime() {
    log "Configuring Docker to use the NVIDIA runtime..."
    nvidia-ctk runtime configure --runtime=docker

    log "Enabling volume mount support for Kind..."
    nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place
}

# restart_docker
# Restarts the Docker daemon to apply the new configuration.
restart_docker() {
    log "Restarting Docker daemon..."
    if command -v systemctl &>/dev/null; then
        systemctl restart docker
    else
        service docker restart
    fi
}

# --- Main Execution ---

main() {
    check_root
    log "Starting NVIDIA Container Toolkit setup..."

    DISTRO="{{ .Distro }}"

    case "$DISTRO" in
    "debian")
        install_toolkit_debian
        ;;
    "rhel")
        install_toolkit_rhel
        ;;
    "suse")
        install_toolkit_suse
        ;;
    *)
        error "Unsupported distribution: $DISTRO. Please refer to NVIDIA's official documentation."
        ;;
    esac

    configure_nvidia_runtime
    restart_docker

    log "✅ NVIDIA Container Toolkit setup complete!"
    log "   Run 'bi gpu validate-nvidia-ctk' to verify your setup."
}

main

exit 1
