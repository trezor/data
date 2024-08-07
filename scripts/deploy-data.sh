#!/usr/bin/env bash

# Before first use:
# Install awscli (pip install awscli)
# Configure access credentials (aws configure), region is "eu-central-1"

DIRS="bootloader bridge firmware legal registry udev suite connect security transparency misc"
BUCKET=data.trezor.io
DISTRIBUTION_ID="E1ERY5K2OTKKI1"

if ! ./check_releases.py; then
    echo "check_releases.py failed."
    exit
fi

set -e

# Disable rollback in favor of versioned bucket
# aws s3 sync s3://$BUCKET s3://$ROLLBACK

for DIR in $DIRS; do
    if [ "$1" == "-d" ]; then
        aws s3 sync --delete --cache-control 'public, max-age=3600' "$DIR" s3://$BUCKET/"$DIR"
    else
        aws s3 sync --cache-control 'public, max-age=3600' "$DIR" s3://$BUCKET/"$DIR"
    fi
done

aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'

echo "DONE"
