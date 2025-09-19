#!/usr/bin/env bash
#
# This is the script that will check to make sure bi is installed
# and then it will run bi start against the provided spec url.
#
# It assumes that functions from common.sh are available.

INSTALL_SPEC_URL="<%= spec_url %>"

# install bi if needed first
check_bi_version || install_bi

# The location of the bi binary
# This is usually VERSION_LOC but can be overridden with BI_OVERRIDE_LOC
BI_INSTALL_LOC="${BI_OVERRIDE_LOC:-$VERSION_LOC}"

# start install
"${BI_INSTALL_LOC}" start \
    ${TRACE:+-v=debug} \
    ${BI_ADDITIONAL_HOSTS:+--additional-insecure-hosts=$BI_ADDITIONAL_HOSTS} \
    ${BI_DISABLE_GPU:+--nvidia-auto-discovery=false} \
    "${INSTALL_SPEC_URL}"
