#!/bin/bash

source setup_env.sh

if [ -n "$SETUP_SQUID" ]; then
    source /etc/profile.d/proxy.sh
fi

#check for network access
network_available=1
max_tries=6
for (( i=0; i < ${max_tries} ; i++ )); do
  curl_output=`curl --connect-timeout 5 -I http://www.google.com | grep '200 OK'`
  if [[ ${curl_output} =~ "200 OK" ]]; then
    network_available=0
    break
  else
    sleep 10
  fi
done

if [[ ${network_available} -ne 0 ]]; then
  echo 'no network available, cannot continue'
  exit 1
fi

bash install_jdk.sh
bash install_maven.sh
bash install_bdconfig.sh

bash setup_hadoop_user.sh
bash mount_disks.sh
bash install_hadoop.sh
bash configure_hadoop.sh
bash configure_hadoop_restart_datanode.sh
bash configure_hdfs.sh
bash set_default_hadoop_fs.sh
bash configure_gcs_connector_datanode.sh
bash setup_datanode_ssh.sh
if [ -n "$SETUP_SQUID" ]; then
  bash configure_hadoop_proxy.sh
fi

bash cleanup_datanode.sh
