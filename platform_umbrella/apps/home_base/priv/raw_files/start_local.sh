#!/usr/bin/env bash
#
# This will check to make sure bi is installed
# Then it will run bi start-local which creates a local installation without
# needing to register.

# install bi if needed first
check_bi_version || install_bi

# The location of the bi binary
# This is usually VERSION_LOC but can be overridden with BI_OVERRIDE_LOC
BI_INSTALL_LOC="${BI_OVERRIDE_LOC:-$VERSION_LOC}"

# start install
"${BI_INSTALL_LOC}" start-local \
    ${TRACE:+-v=debug} \
    ${BI_DISABLE_GPU:+--nvidia-auto-discovery=false}
