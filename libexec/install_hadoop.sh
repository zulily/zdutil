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

# Downloads and installs all appropriate hadoop packages as user 'hadoop'.
# Also adds installation specific configs into the login scripts of user
# 'hadoop'.
#!/bin/bash

echo 'Installing hadoop'

set -e

INSTALL_TMP_DIR=${INSTALL_TMP_DIR}/hadoop-$(date +%s)
mkdir -p ${INSTALL_TMP_DIR}

HADOOP_TARBALL=${HADOOP_TARBALL_URI##*/}
HADOOP_TARBALL_URI_SCHEME=${HADOOP_TARBALL_URI%%://*}
if [[ "${HADOOP_TARBALL_URI_SCHEME}" == gs ]]; then
  gsutil cp ${HADOOP_TARBALL_URI} ${INSTALL_TMP_DIR}/${HADOOP_TARBALL}
elif [[ "${HADOOP_TARBALL_URI_SCHEME}" =~ ^https?$ ]]; then
  wget ${HADOOP_TARBALL_URI} -O ${INSTALL_TMP_DIR}/${HADOOP_TARBALL}
else
  echo "Unknown scheme \"${HADOOP_TARBALL_URI_SCHEME}\" in HADOOP_TARBALL_URI: \
$HADOOP_TARBALL_URI" >&2
  exit 1
fi
tar -C ${INSTALL_TMP_DIR} -xvzf ${INSTALL_TMP_DIR}/${HADOOP_TARBALL}
mkdir -p $(dirname ${HADOOP_INSTALL_DIR})
mv ${INSTALL_TMP_DIR}/hadoop*/ ${HADOOP_INSTALL_DIR}

chown -R hadoop:hadoop  ${HADOOP_INSTALL_DIR}

# Hadoop 2 tarballs only come with 32-bit binaries that cause the JVM to
# complain.
find ${HADOOP_INSTALL_DIR}/lib -follow -xtype f \
    | xargs -r file -Le elf | grep '32-bit' | cut -d':' -f1 | xargs -r rm -f

# Update login scripts
cat << EOF | tee -a /etc/profile.d/hadoop >> /etc/*bashrc
if [ -r "${HADOOP_INSTALL_DIR}/libexec/hadoop-config.sh" ]; then
  . "${HADOOP_INSTALL_DIR}/libexec/hadoop-config.sh"
fi
if [ -d "${HADOOP_INSTALL_DIR}/bin" ]; then
  export PATH=\$PATH:${HADOOP_INSTALL_DIR}/bin
fi
EOF

