#!/usr/bin/env bash

# This is basically copy-paste of
#     https://github.com/trezor/trezor-suite/blob/develop/packages/connect-common/scripts/check-all-firmware-revisions.sh
#
#     Small adjustments are made because here we check releases.json here in data/firmware, not those in trezor-suite/connect-common.
#     Please keep them in sync if possible.
#

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )

cd "$PARENT_PATH/../firmware" || exit

EXCLUDED_DIR="translations"

for dir in */ ; do
    DEVICE=${dir%/}
    if [[ $EXCLUDED_DIR == "$DEVICE" ]]; then continue; fi
    if [ -d "$dir" ]; then
        if ! "$PARENT_PATH/check-firmware-revisions.sh" "$DEVICE" ; then
            exit 1
        fi;
    fi
done
