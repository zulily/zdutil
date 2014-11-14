#!/bin/bash

set -e

gcloud components update -q

source setup_env.sh

bash install_jdk.sh
bash install_maven.sh
bash install_bdconfig.sh

bash setup_hadoop_user.sh
bash mount_disks.sh
bash install_hadoop.sh
bash configure_hadoop.sh
bash configure_hdfs.sh
bash set_default_hadoop_fs.sh
bash configure_gcs_connector_namenode.sh
bash setup_namenode_ssh.sh

if [ -n "$SETUP_SQUID" ]; then
  bash setup_squid_namenode.sh
  bash configure_hadoop_proxy.sh
fi

bash setup_datanodes_remote.sh

bash start_hadoop.sh
