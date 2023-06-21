#!/bin/bash

set -e

PROJECT_PATH="$(pwd)"

MAGENTO_PATH="$PROJECT_PATH"

if [ -d "$PROJECT_PATH$INPUT_MAGENTO_PATH" ]
then
    MAGENTO_PATH="$PROJECT_PATH$INPUT_MAGENTO_PATH"
fi

PWA_PATH="$PROJECT_PATH/pwa"
if [ -n $INPUT_PWA_PATH ]
then
  PWA_PATH="$PROJECT_PATH$INPUT_PWA_PATH"
fi

echo "project path is $PROJECT_PATH";

which ssh-agent || ( apt-get update -y && apt-get install openssh-client -y )
eval $(ssh-agent -s)
mkdir ~/.ssh/ && echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa && chmod 600 ~/.ssh/id_rsa
ssh-add ~/.ssh/id_rsa
echo "$SSH_CONFIG" > /etc/ssh/ssh_config && chmod 600 /etc/ssh/ssh_config

echo "Create artifact and send to server"

cd $PROJECT_PATH

echo "Deploying to staging server";

mkdir -p deployer/scripts/
cp -R /opt/config/pipelines/scripts/staging deployer/scripts/staging

echo 'creating bucket dir'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "mkdir -p $HOST_DEPLOY_PATH_BUCKET"

ARCHIVES="deployer/scripts/staging"

# since we are using custom directory, we need to copy build magento content to 'magento' folder

if [ -n "$ENV_VALUES" ]
then
  echo "$ENV_VALUES" > $MAGENTO_PATH/app/etc/env.php
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  $MAGENTO_PATH/app/etc/env.php staging:$HOST_DEPLOY_PATH/shared/magento/app/etc/
  echo "Magento env.php values set successfully."
fi

cp -r "$MAGENTO_PATH/app" "magento" 
cp -r "$MAGENTO_PATH/pub" "magento" 
cp -r "$MAGENTO_PATH/generated" "magento" 
cp -r "$MAGENTO_PATH/vendor" "magento" 
cp -r "$MAGENTO_PATH/var" "magento" 

[ -d "$PWA_PATH" ] && cp -a "$PWA_PATH/." "pwa-studio" 

[ -d "pwa-studio" ] && ARCHIVES="$ARCHIVES pwa-studio"
[ -d "magento" ] && ARCHIVES="$ARCHIVES magento"


tar cfz "$BUCKET_COMMIT" $ARCHIVES
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  "$BUCKET_COMMIT" staging:$HOST_DEPLOY_PATH_BUCKET


cd /opt/config/php-deployer

echo 'Deploying staging ...';

echo '------> Deploying bucket ...';
# deploy bucket
php7.4 ./vendor/bin/dep deploy-bucket staging \
-o bucket-commit=$BUCKET_COMMIT \
-o host_bucket_path=$HOST_DEPLOY_PATH_BUCKET \
-o deploy_path_custom=$HOST_DEPLOY_PATH \
-o deploy_keep_releases=$INPUT_KEEP_RELEASES \
-o write_use_sudo=$WRITE_USE_SUDO

echo '------> Deploying bucket complete ...';

# Run pre-release script in order to setup the server before magento deploy
echo "MAGENTO_PATH set as $MAGENTO_PATH"

if [ -d "$MAGENTO_PATH" ]
then
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "cd $HOST_DEPLOY_PATH/release/magento/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/staging/release_setup.sh"
fi

echo '------> Deploying release ...';

DEFAULT_DEPLOYER="deploy"
if [ $INPUT_DEPLOYER = "no-permission-check" ]
then
  DEFAULT_DEPLOYER="deploy:no-permission-check"
  if [ ! -d "$MAGENTO_PATH" ]
    then
      DEFAULT_DEPLOYER="deploy:no-permission-check:pwa-only"
  fi
fi

# deploy release
php7.4 ./vendor/bin/dep $DEFAULT_DEPLOYER staging \
-o bucket-commit=$BUCKET_COMMIT \
-o host_bucket_path=$HOST_DEPLOY_PATH_BUCKET \
-o deploy_path_custom=$HOST_DEPLOY_PATH \
-o deploy_keep_releases=$INPUT_KEEP_RELEASES \
-o write_use_sudo=$WRITE_USE_SUDO

echo "running magento and/or pwa deployer"
if [ -d "$MAGENTO_PATH" ]
then
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "cd $HOST_DEPLOY_PATH/current/magento/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/staging/post_release_setup.sh"
fi

# Run pwa-studio post release script if the directory exists
PWA_PATH=$PROJECT_PATH

if [ -n $INPUT_PWA_PATH ]
then
  PWA_PATH="$PROJECT_PATH$INPUT_PWA_PATH"
fi

if [ -d "$PWA_PATH" ]
then
 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "cd $HOST_DEPLOY_PATH/current/pwa-studio/ && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/staging/post_release_setup_pwa_studio.sh"
fi

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "cd $HOST_DEPLOY_PATH_BUCKET && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/staging/post_release_cleanup.sh $INPUT_KEEP_RELEASES"

if [-n $HOST_DEPLOY_PATH_RELEASES ]
then
  echo "cleaning up releases"
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null  staging "cd $HOST_DEPLOY_PATH_RELEASES && /bin/bash $HOST_DEPLOY_PATH/deployer/scripts/staging/post_release_cleanup.sh $INPUT_KEEP_RELEASES"
fi