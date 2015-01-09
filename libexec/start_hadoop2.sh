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

# Starts relevant hadoop daemon servers as the 'hadoop' user.
#!/bin/bash

set -e

cd ${HADOOP_INSTALL_DIR}

# Test for sshability to workers.
count=$(($NUM_WORKERS - 1))
for i in `seq 0 $count`;
do
  NODE="${PREFIX}-dn-${i}"
  sudo -u hadoop ssh ${NODE} "exit 0"
done

if (( ${ENABLE_HDFS} )); then

  if [ -z "$(find /mnt/*/hadoop/ /hadoop/ -maxdepth 4 \
      -wholename '*/name/current/VERSION')" ]; then
    # namenode is not formatted
    sudo -u hadoop ./bin/hdfs namenode -format
  fi

  sudo -u hadoop ./sbin/start-dfs.sh

fi

# Start up resource and node managers
sudo -u hadoop ./sbin/start-yarn.sh
