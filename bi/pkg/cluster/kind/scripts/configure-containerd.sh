#!/bin/bash
set -e

# Tell containerd that nvidia-container-runtime is available
nvidia-ctk runtime configure --runtime=containerd --config-source=command

# Follow Microsoft's lead and fix everything by turning it off and on again
systemctl restart containerd
