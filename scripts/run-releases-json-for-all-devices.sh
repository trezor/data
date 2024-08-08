#!/usr/bin/env bash

DEVICE_PATHS=$(find firmware -maxdepth 1 -type d ! -name 'translations' ! -name 'README.md' ! -name 'firmware')

for FILE in $DEVICE_PATHS; 
    do 
        DEVICE_MODEL=$(basename "$FILE")
        if ! ./scripts/check-firmware-presence-in-releases-json.sh "$DEVICE_MODEL" ; then
            exit 1
        fi;
        
        echo
    done
