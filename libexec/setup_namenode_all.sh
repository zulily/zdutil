#!/bin/bash

set -e

bash setup_gcloud.sh

source setup_env.sh

bash install_jdk.sh
bash install_maven.sh
bash install_bdconfig.sh

bash setup_hadoop_user.sh
bash mount_disks.sh
bash install_hadoop.sh
bash configure_hadoop.sh
bash configure_hadoop_restart_namenode.sh
bash configure_hdfs.sh
bash set_default_hadoop_fs.sh
bash configure_gcs_connector_namenode.sh
bash setup_namenode_ssh.sh

if [ -n "$SETUP_SQUID" ]; then
  bash setup_squid_namenode.sh
  bash configure_hadoop_proxy.sh
fi

bash setup_datanodes_remote.sh

if [[ "$HADOOP_VERSION" = "1.x" ]]; then
 bash start_hadoop1.sh
else
 bash start_hadoop2.sh
fi

bash cleanup_namenode.sh