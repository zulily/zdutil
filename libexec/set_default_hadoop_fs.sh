
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
# and the xml files which go under the 'conf/' directory of the hadoop
# installation.
#!/bin/bash

echo 'Setting hadoop fs'

set -e

# Set FS specific config variables
if [[ "${DEFAULT_FS}" == "gs" ]]; then
  DEFAULT_FS_NAME="gs://${CONFIGBUCKET}/"
elif [[ "${DEFAULT_FS}" == "hdfs" ]]; then
  DEFAULT_FS_NAME="${NAMENODE_URI}"
fi

bdconfig set_property \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --name 'fs.default.name' \
    --value ${DEFAULT_FS_NAME} \
    --clobber

bdconfig set_property \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --name 'fs.defaultFS' \
    --value ${DEFAULT_FS_NAME} \
    --clobber
