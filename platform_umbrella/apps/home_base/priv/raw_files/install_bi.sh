#!/usr/bin/env bash
#
# This is the script that will install bi if needed.
# It assumes that functions from common.sh are available.

check_bi_version || install_bi
check_installed "${BI}" || install_bi
