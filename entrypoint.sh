#!/bin/sh -l

echo "hello your setup is $INPUT_PHP & $INPUT_PROCESS & $INPUT_OVERRIDE_SETTINGS"


bash /opt/config/utils/project-format-checker.sh

if [ $INPUT_PHP = 'auto' ]
then
  bash /opt/config/utils/php-compatibility-checker.sh
else
  echo "Forcing php to match specified input argument"
  update-alternatives --set php /usr/bin/php${INPUT_PHP}
  echo "php version set to: $(php --version)"
fi

echo "Input search engine specifications"
echo "Elasticsearch: $INPUT_ELASTICSEARCH"
echo "Opensearch: $INPUT_OPENSEARCH"
bash /opt/config/utils/search-engine-compatibility-checker.sh


if [ "$INPUT_COMPOSER_VERSION" -ne 0 ]
then
  echo "Forcing composer to match specified input argument"
  php7.2 /usr/local/bin/composer self-update --${INPUT_COMPOSER_VERSION}
fi


if [ $INPUT_OVERRIDE_SETTINGS = 1 ]
then
  [ -d config ] && ls ./config/*
  [ -d scripts ] && ls ./scripts/*
  [ -d config ] && cp -rf ./config/* /opt/config/
  [ -d scripts ] && cp -rf ./scripts/* /opt/scripts/
  bash /opt/scripts/${INPUT_PROCESS}.sh
else
  bash /opt/scripts/${INPUT_PROCESS}.sh
fi
