#!/bin/bash
set -Eeuo pipefail

# Patch NVIDIA driver parameters if they exist
if [ -f /proc/driver/nvidia/params ]; then
    cp /proc/driver/nvidia/params root/gpu-params
    sed -i 's/^ModifyDeviceFiles: 1$/ModifyDeviceFiles: 0/' root/gpu-params
    mount --bind root/gpu-params /proc/driver/nvidia/params
else
    echo "NVIDIA driver params not found, skipping"
fi
