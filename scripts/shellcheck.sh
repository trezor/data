#!/usr/bin/env bash

set -e
set -u
set -x
set -o pipefail

shellcheck --version

find . -type f -name '*.sh' -exec shellcheck {} +
