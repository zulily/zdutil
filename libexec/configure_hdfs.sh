# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Configures HDFS to use mounted directories
#!/bin/bash

echo 'Configuring hdfs'

set -e
if (( ${ENABLE_HDFS} )); then

  HDFS_ADMIN=hadoop

  # Location of HDFS metadata on namenode
  export HDFS_NAME_DIR=/hadoop/dfs/name

  # If disks are mounted use all of them for HDFS data
  if ! MOUNTED_DISKS=($(find /mnt/* -maxdepth 0)); then
    MOUNTED_DISKS=('')
  fi
  # Location of HDFS data blocks on data nodes
  HDFS_DATA_DIRS="${MOUNTED_DISKS[@]/%//hadoop/dfs/data}"

  # Do not create HDFS_NAME_DIR, or Hadoop with think it is already formatted
  mkdir -p ${HDFS_DATA_DIRS}

  chown ${HDFS_ADMIN}:hadoop -L -R /hadoop/dfs ${HDFS_DATA_DIRS}
  chmod 755 ${HDFS_DATA_DIRS}

  # Set general Hadoop environment variables

  # Calculate the memory allocations, MB, using 'free -m'. Floor to nearest MB.
  TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
  NAMENODE_MEM_MB=$(python -c "print int(${TOTAL_MEM} * 0.2)")
  SECONDARYNAMENODE_MEM_MB=${NAMENODE_MEM_MB}

  cat << EOF >> ${HADOOP_CONF_DIR}/hadoop-env.sh

# Increase the maximum NameNode / SecondaryNameNode heap.
HADOOP_NAMENODE_OPTS="-Xmx${NAMENODE_MEM_MB}m \${HADOOP_NAMENODE_OPTS}"
HADOOP_SECONDARYNAMENODE_OPTS="-Xmx${SECONDARYNAMENODE_MEM_MB}m \${HADOOP_SECONDARYNAMENODE_OPTS}"
EOF

  export HDFS_DATA_DIRS="${HDFS_DATA_DIRS// /,}"

  bdconfig merge_configurations \
      --configuration_file ${HADOOP_CONF_DIR}/hdfs-site.xml \
      --source_configuration_file hdfs-template.xml \
      --resolve_environment_variables \
      --create_if_absent \
      --clobber
fi
