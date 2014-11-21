#!/bin/bash

if ! type "gcloud" > /dev/null; then
  wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz
  tar -zxf google-cloud-sdk.tar.gz
  python google-cloud-sdk/bin/bootstrapping/install.py --usage-reporting false --rc-path /home/$SUDO_USER/.bash_profile --bash-completion false --path-update true
  source /home/$SUDO_USER/.bash_profile
fi

gcloud components update -q
