#!/usr/bin/env bash

set -e

echo "keep release number: $1"

echo "cleaning up buckets"

KEEP_RELEASE_NR="NR>$1";

rm -rf `ls -t | awk $KEEP_RELEASE_NR`