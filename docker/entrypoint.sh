#!/usr/bin/env bash

set -euo pipefail

exec /usr/bin/tini -- "$BINARY" start
