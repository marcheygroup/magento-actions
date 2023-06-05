#!/usr/bin/env bash

set -e

PROJECT_PATH="$(pwd)"

mkdir -p ~/.n98-magerun2/modules
cd ~/.n98-magerun2/modules
git clone https://github.com/gwillem/magevulndb.git

MAGENTO_PATH="$PROJECT_PATH"

if [ -d "$PROJECT_PATH$INPUT_MAGENTO_PATH" ]
then
    MAGENTO_PATH="$PROJECT_PATH$INPUT_MAGENTO_PATH"
fi

echo "MAGENTO_PATH set as $MAGENTO_PATH"

cd $MAGENTO_PATH

php /opt/magerun/n98-magerun2-latest.phar dev:module:security

