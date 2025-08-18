#!/usr/bin/env bash
#
# This will check to make sure bi is installed
# Then it will run bi start-local which creates a local installation without
# needing to register.

# install bi if needed first
check_bi_version || install_bi

# start install
"${VERSION_LOC}" start-local \
    ${TRACE:+-v=debug} \
    ${BI_DISABLE_GPU:+--nvidia-auto-discovery=false}
