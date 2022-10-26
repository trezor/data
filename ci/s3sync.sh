#!/usr/bin/env bash

# Before first use:
# Install awscli (pip install awscli)
# Configure access credentials (aws configure), region is "eu-central-1"

DIRS="bootloader bridge firmware legal registry udev suite connect security transparency"
BUCKET=data.trezor.io
ROLLBACK=rollback-data.trezor.io
DISTRIBUTION_ID="E1ERY5K2OTKKI1"

./check_releases.py
if [ "$?" != "0" ]; then
    echo "check_releases.py failed."
    exit
fi

set -e

aws s3 sync s3://$BUCKET s3://$ROLLBACK

for DIR in $DIRS; do
    if [ "x$1" == "x-d" ]; then
        aws s3 sync --delete --cache-control 'public, max-age=3600' $DIR s3://$BUCKET/$DIR
    else
        aws s3 sync --cache-control 'public, max-age=3600' $DIR s3://$BUCKET/$DIR
    fi
done

aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'

echo "DONE"
