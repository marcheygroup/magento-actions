#!/usr/bin/env bash

PROJECT_PATH="$(pwd)"

echo "currently in $PROJECT_PATH"

MAGENTO_PATH="$PROJECT_PATH"

if [ -d "$PROJECT_PATH$INPUT_MAGENTO_PATH" ]
then
    MAGENTO_PATH="$PROJECT_PATH$INPUT_MAGENTO_PATH"
fi

cd "$MAGENTO_PATH"

/usr/local/bin/composer install --dry-run --prefer-dist --no-progress &> /dev/null

COMPOSER_COMPATIBILITY=$?

echo "Composer compatibility: $COMPOSER_COMPATIBILITY"


set -e

if [ $COMPOSER_COMPATIBILITY = 0 ]
then
	/usr/local/bin/composer install --prefer-dist --no-progress
else
  echo "using composer v1"
  php7.2 /usr/local/bin/composer self-update --1
	/usr/local/bin/composer install --prefer-dist --no-progress
fi


git clone https://github.com/seyuf/magento-malware-scanner

cd magento-malware-scanner/

pip install --upgrade yara-python psutil requests>=0.8.2

python setup.py install --record $PROJECT_PATH/files.txt

cd .. && rm -r magento-malware-scanner/

mwscan --ruleset madit  .



