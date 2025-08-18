#!/bin/bash
set -Eeuo pipefail

apt-get update
# gpg to sign things
# curl to reach the interwebs
apt-get install -y gpg curl

# Secure
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
# Add the new Source
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Fetch what can be installed now. It should include the
# NVIDIA container toolkit
apt-get update

# Yep
apt-get install -y nvidia-container-toolkit \
    nvidia-container-toolkit-base \
    libnvidia-container-tools \
    libnvidia-container1
