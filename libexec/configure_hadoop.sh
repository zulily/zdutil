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

# Generates the config files which will be needed by the hadoop servers such
# as 'slaves' listing all datanode hostnames, 'masters' listing the namenode,
# and the xml files which go in the Hadoop configuration directory
#!/bin/bash

echo 'Configuring hadoop'

set -e

# Used for hadoop.tmp.dir
export HADOOP_TMP_DIR=/hadoop/tmp
mkdir -p ${HADOOP_TMP_DIR}

chgrp hadoop -L -R /hadoop ${HADOOP_TMP_DIR}
chmod g+rwx -R /hadoop
chmod 777 -R ${HADOOP_TMP_DIR}

count=$(($NUM_WORKERS - 1))
for i in `seq 0 $count`;
do
WORKERS[${i}]="${PREFIX}-dn-${i}"
done
echo ${WORKERS[@]} | tr ' ' '\n' > ${HADOOP_CONF_DIR}/slaves
echo ${NAMENODE_HOSTNAME} > ${HADOOP_CONF_DIR}/masters

# Basic configuration not related to GHFS or HDFS.
# Rough rule-of-thumb settings for default maps/reduces taken from
# http://wiki.apache.org/hadoop/HowManyMapsAndReduces
export DEFAULT_NUM_MAPS=$((${NUM_WORKERS} * 10))
export DEFAULT_NUM_REDUCES=$((${NUM_WORKERS} * 4))

NUM_CORES="$(grep -c processor /proc/cpuinfo)"
export MAP_SLOTS=${NUM_CORES}
export REDUCE_SLOTS=${NUM_CORES}

# Set general Hadoop environment variables
JAVA_HOME=$(readlink -f $(which java) | sed 's|/bin/java$||')

# Calculate the memory allocations, MB, using 'free -m'. Floor to nearest MB.
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
JOBTRACKER_MEM_MB=$(python -c "print int(${TOTAL_MEM} * 0.4)")
RESOURCEMANAGER_MEM_MB=${JOBTRACKER_MEM_MB}

# Total mem allocation for datanode/tasktracker instances:
#   1000MB for tasktracker daemon
#   1000MB for datanode daemon
#    400MB for misc/free
#   divide the rest evenly among the available map/reduce slots (jobs can override
#   this if needed)
MAP_RED_MAX_HEAP=$(python -c "print int((${TOTAL_MEM} - 2400)) / (${MAP_SLOTS} + ${REDUCE_SLOTS})")
export MAP_RED_TASK_OPTS="-Xmx${MAP_RED_MAX_HEAP}m -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:CMSInitiatingOccupancyFraction=40 -XX:+UseCMSInitiatingOccupancyOnly"

cat << EOF >> ${HADOOP_CONF_DIR}/hadoop-env.sh
export JAVA_HOME=${JAVA_HOME}

# Place HADOOP_LOG_DIR in /hadoop (possibly on larger non-boot-disk)
export HADOOP_LOG_DIR=/hadoop/logs

# Increase maximum JobTracker Heap
HADOOP_JOBTRACKER_OPTS="-Xmx${JOBTRACKER_MEM_MB}m \${HADOOP_JOBTRACKER_OPTS}"
EOF

bdconfig merge_configurations \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --source_configuration_file core-template.xml \
    --resolve_environment_variables \
    --create_if_absent \
    --clobber

bdconfig merge_configurations \
    --configuration_file ${HADOOP_CONF_DIR}/mapred-site.xml \
    --source_configuration_file mapred-template.xml \
    --resolve_environment_variables \
    --create_if_absent \
    --clobber

if [[ -f yarn-template.xml ]]; then
  bdconfig merge_configurations \
      --configuration_file ${HADOOP_CONF_DIR}/yarn-site.xml \
      --source_configuration_file yarn-template.xml \
      --resolve_environment_variables \
      --create_if_absent \
      --clobber

  if [[ "${DEFAULT_FS}" == "gs" ]]; then
    bdconfig set_property \
        --configuration_file ${HADOOP_CONF_DIR}/yarn-site.xml \
        --name 'yarn.log-aggregation-enable' \
        --value 'true' \
        --clobber
  fi
fi
