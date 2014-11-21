# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,f
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Sets up ssh keys on the namenode and then uploads them to a GCS CONFIGBUCKET
# for datanodes to later download.
#!/bin/bash

echo 'Configuring hadoop ssh'

set -e

rm -rf /home/hadoop/.ssh
mkdir -p /home/hadoop/.ssh/
chmod 700 /home/hadoop/.ssh

PRIVATE_KEY_NAME='hadoop_master_id_rsa'
PUBLIC_KEY_NAME="${PRIVATE_KEY_NAME}.pub"
LOCAL_PUBLIC_KEY="/home/hadoop/.ssh/${PUBLIC_KEY_NAME}"
REMOTE_PUBLIC_KEY="${BDUTIL_GCS_STAGING_DIR}/${PUBLIC_KEY_NAME}"
LOCAL_PRIVATE_KEY="/home/hadoop/.ssh/${PRIVATE_KEY_NAME}"

if [ -e ${LOCAL_PRIVATE_KEY} ]
then
	rm -f ${LOCAL_PUBLIC_KEY}
	rm -f ${LOCAL_PRIVATE_KEY}
fi

ssh-keygen -N "" -f ${LOCAL_PRIVATE_KEY}

# Authorize ssh into self as well, in case the namenode is also a worker node.
cat ${LOCAL_PUBLIC_KEY} >> /home/hadoop/.ssh/authorized_keys

echo "Host ${PREFIX}*" >> /home/hadoop/.ssh/config
echo "  IdentityFile ${LOCAL_PRIVATE_KEY}" >> /home/hadoop/.ssh/config
echo '  UserKnownHostsFile /dev/null' >> /home/hadoop/.ssh/config
echo '  CheckHostIP no' >> /home/hadoop/.ssh/config
echo '  StrictHostKeyChecking no' >> /home/hadoop/.ssh/config

gsutil cp ${LOCAL_PUBLIC_KEY} ${REMOTE_PUBLIC_KEY}

chown -R hadoop:hadoop ~hadoop/.ssh/
chmod 700 ~hadoop/.ssh
