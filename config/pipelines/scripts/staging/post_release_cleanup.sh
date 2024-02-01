#!/usr/bin/env bash

set -e

echo "keep release number: $1"

echo "cleaning up buckets"

KEEP_RELEASE_NR="NR>$1";

echo $(ls -t | awk $KEEP_RELEASE_NR)
echo $(pwd)

rm -rf `ls -t | awk $KEEP_RELEASE_NR`

echo $(ls)

if service --status-all | grep -Fq 'php8.1-fpm'; then    
  sudo service php8.1-fpm restart    
  echo "service php8.1-fpm restarted"
fi

if service --status-all | grep -Fq 'php8.2-fpm'; then    
  sudo service php8.2-fpm restart    
  echo "service php8.2-fpm restarted"
fi
