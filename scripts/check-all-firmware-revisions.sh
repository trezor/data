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

IS_LEGACY="false"

for dir in */ ; do
    DEVICE=${dir%/}
    # TODO: we excude t3w1 until we have releases on it.
    if [[ $EXCLUDED_DIR == "$DEVICE" || $DEVICE == "t3w1" ]]; then continue; fi
        is_legacy_for_device="$IS_LEGACY"
    if [[ "$DEVICE" == "1" || "$DEVICE" == "2" ]]; then
        is_legacy_for_device="true"
    fi
    if [ -d "$dir" ]; then
        if ! "$PARENT_PATH/check-firmware-revisions.sh" "$DEVICE" "$is_legacy_for_device" ; then
            exit 1
        fi;
    fi
done
