#!/usr/bin/env bash

set -e

echo "keep release number: $1"

echo "cleaning up buckets"

KEEP_RELEASE_NR="NR>$1";

echo "$(pwd)"

echo "$KEEP_RELEASE_NR"

rm -f `ls -t | awk $KEEP_RELEASE_NR`