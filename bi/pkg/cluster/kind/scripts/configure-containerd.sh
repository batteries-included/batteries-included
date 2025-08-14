#!/bin/bash
set -Eeuo pipefail

# Tell containerd that nvidia-container-runtime is available
echo "Configuring containerd to use nvidia-container-runtime..."
nvidia-ctk runtime configure --runtime=containerd --config-source=command --cdi.enabled
echo "Configuring containerd to use devices through volume mounts..."
nvidia-ctk config --set accept-nvidia-visible-devices-as-volume-mounts=true --in-place

# Follow Microsoft's lead and fix everything by turning it off and on again
echo "Restarting containerd..."
systemctl restart containerd
