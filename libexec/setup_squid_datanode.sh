#!/bin/bash

echo 'Configuring proxy settings'

source setup_env.sh

echo "export http_proxy=\"http://${PREFIX}-nn.$(dnsdomainname):3128\"" >> /etc/profile.d/proxy.sh
echo "export https_proxy=\"http://${PREFIX}-nn.$(dnsdomainname):3128\"" >> /etc/profile.d/proxy.sh
echo "export ftp_proxy=\"http://${PREFIX}-nn.$(dnsdomainname):3128\"" >> /etc/profile.d/proxy.sh
echo "export no_proxy=169.254.169.254,metadata,metadata.google.internal" >> /etc/profile.d/proxy.sh

# Update sudoers to pass these env variables through
cp /etc/sudoers /tmp/sudoers.new
chmod 640 /tmp/sudoers.new
echo "Defaults env_keep += \"ftp_proxy http_proxy https_proxy no_proxy"\" >>/tmp/sudoers.new
chmod 440 /tmp/sudoers.new
visudo -c -f /tmp/sudoers.new && cp /tmp/sudoers.new /etc/sudoers
