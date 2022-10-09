#!/bin/bash
set -ueo pipefail

# Helper for setting up Ubuntu-esque environments

PACKAGES=(
  # for everything
  build-essential procps curl file git
  unzip libssl-dev automake autoconf
  libncurses5-dev
  # for us
  chromium-chromedriver
  # for insurance, linux should have this stuff
  ca-certificates lsb-release
)

# packages!
sudo apt install -y "${PACKAGES[@]}"
