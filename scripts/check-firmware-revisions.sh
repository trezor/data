#!/usr/bin/env bash

# This is basically copy-paste of
#     https://github.com/trezor/trezor-suite/blob/develop/packages/connect-common/scripts/check-firmware-revisions.sh
#
#     Small adjustments are made because here we check releases.json here in data/firmware, not those in trezor-suite/connect-common.
#     Please keep them in sync if possible.
#

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )

if [[ $# -ne 2 ]]
    then
        echo "must provide 2 argument. $# provided"
        exit 1
fi

DEVICE=$1
IS_LEGACY=$2

RELEASES_FOLDER="$PARENT_PATH"/../firmware

EXCLUDED_DIR="translations"

if [[ $EXCLUDED_DIR == "$DEVICE" ]]; then
    echo "Invalid device $DEVICE, this is a reserved folder."
    exit 1
fi
if ! test -d "$RELEASES_FOLDER/$DEVICE"; then
    echo "Device $DEVICE not found in releases folder!"
    exit 1
fi

echo "CHECKING RELEASES FOR $DEVICE"

BRANCH="main"
REPO_DIR_NAME=$PARENT_PATH"/../../trezor-firmware-for-revision-check"

cd ..

if test -d "$REPO_DIR_NAME"; then
    echo "$REPO_DIR_NAME directory exists"
else
    echo "$REPO_DIR_NAME directory does not exist"
    git clone https://github.com/trezor/trezor-firmware.git "$REPO_DIR_NAME"
fi

cd "$REPO_DIR_NAME" || exit
git fetch origin
git checkout "$BRANCH"
git reset "origin/$BRANCH" --hard


DATA=""

# When checking legacy "1" and "2" directories we do not check `bitcoinonly` and `universal` directories
# with new format, we only check it for legacy `releases.json`. For the rest we check it for both formats.
if [[ "$IS_LEGACY" == "true" ]]; then
  DATA=$(jq -r '.[] | .version |= join(".") | .firmware_revision + "%" + .version' < "$RELEASES_FOLDER/$DEVICE"/releases.json)
else
  DATA=$(
    jq -r '.[] | .version |= join(".") | .firmware_revision + "%" + .version' < "$RELEASES_FOLDER/$DEVICE"/releases.json
    jq -r '.version |= join(".") | .firmware_revision + "%" + .version' "$RELEASES_FOLDER/$DEVICE"/{bitcoinonly,universal}/*.json
  )
fi

for ROW in $DATA;
do
    FW_REVISION=$(echo "$ROW" | cut -d"%" -f1)
    EXPECTED_TAG=$([[ "$DEVICE" == "t1b1" || "$DEVICE" == "1" ]] && echo "legacy" || echo "core")/v$(echo "$ROW" | cut -d"%" -f2)

    RESULT_TAGS=$(git tag --points-at "$FW_REVISION")

    for RESULT_TAG in $RESULT_TAGS;
    do
        if [[ "$RESULT_TAG" == "$EXPECTED_TAG" ]]; then
            echo "[$DEVICE] Version $EXPECTED_TAG ... OK"
            continue 2
        fi
    done

    echo "ERROR: [$DEVICE] Tags '$RESULT_TAGS' does not contain expected: '$EXPECTED_TAG' for revision: $FW_REVISION"
    exit 1
done
