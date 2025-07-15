#!/usr/bin/env bash
#
# This is the script that will check to make sure bi is installed
# and then it will run bi start against the provided spec url.
#
# It assumes that functions from common.sh are available.

INSTALL_SPEC_URL="<%= spec_url %>"

# install bi if needed first
check_bi_version || install_bi

# start install
"${VERSION_LOC}" start \
    ${TRACE:+-v=debug} \
    ${BI_ADDITIONAL_HOSTS:+--additional-insecure-hosts=$BI_ADDITIONAL_HOSTS} \
    "${INSTALL_SPEC_URL}"
