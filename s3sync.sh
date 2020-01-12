#!/bin/bash

# Before first use:
# Install awscli (pip install awscli)
# Configure access credentials (aws configure), region is "eu-central-1"

DIRS="bootloader bridge firmware registry udev suite"
BUCKET=data.trezor.io
DISTRIBUTION_ID="E1ERY5K2OTKKI1"

cd `dirname $0`

./check_releases.py
if [ "$?" != "0" ]; then
    echo "check_releases.py failed."
    exit
fi

set -e

read -r -p "Are you sure? [y/N] " response
if [[ $response =~ ^(yes|y)$ ]]; then
    echo "let's go!"
else
    exit 2
fi

for DIR in $DIRS; do
    if [ "x$1" == "x-d" ]; then
        aws s3 sync --delete --cache-control 'public, max-age=3600' --exclude "*.json" --exclude "*.txt" $DIR s3://$BUCKET/$DIR
    else
        aws s3 sync --cache-control 'public, max-age=3600' --exclude "*.json" --exclude "*.txt" $DIR s3://$BUCKET/$DIR
    fi
done

aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'

echo "DONE"
