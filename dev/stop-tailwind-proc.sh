#!/bin/bash

set -exuo pipefail

ps aux | grep [t]ailwind | awk '{print $2}' | xargs kill -9
