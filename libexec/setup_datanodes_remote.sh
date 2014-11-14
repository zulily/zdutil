#!/bin/bash

PRIVATE_KEY_NAME='hadoop_master_id_rsa'
PUBLIC_KEY_NAME="${PRIVATE_KEY_NAME}.pub"
LOCAL_PUBLIC_KEY="/home/hadoop/.ssh/${PUBLIC_KEY_NAME}"

# Repeatedly try to ssh into node until success or limit is reached.
# Will fail if node takes too long.
function wait_for_ssh() {
  trap handle_error ERR
  local node=$1
  local max_attempts=10
  local is_sshable="ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp -A -p 22 ${SUDO_USER}@${node} exit 0"
  local sleep_time=5
  for (( i=0; i < ${max_attempts}; i++ )); do
    if ${is_sshable}; then
      return 0
    else
      # Save the error code responsible for the trap.
      local errcode=$?
      echo "'${node}' not yet sshable (${errcode}); sleeping ${sleep_time}."
      sleep ${sleep_time}
    fi
  done
  echo "Node '${node}' did not become ssh-able after ${max_attempts} attempts" >&2
  exit ${errcode}
}

count=$(($NUM_WORKERS - 1))
for i in `seq 0 $count`;
do
  NODE="${PREFIX}-dn-${i}"
  wait_for_ssh ${NODE}
  echo "Copying files to ${NODE}"
  scp -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp ${LOCAL_PUBLIC_KEY} ${SUDO_USER}@${NODE}:~/
  scp -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp *.sh ${SUDO_USER}@${NODE}:~/
  scp -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp *.xml ${SUDO_USER}@${NODE}:~/
  if [ -n "$SETUP_SQUID" ]; then
    echo "Configuring ${NODE} to use squid proxy"
    scp -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp bigdata-interop-1.3.1-z/gcs/target/gcs-connector-1.3.1-SNAPSHOT-hadoop1-shaded.jar ${SUDO_USER}@${NODE}:~/
    ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp -A -p 22 ${SUDO_USER}@${NODE} 'sudo bash setup_squid_datanode.sh > proxy.log 2>&1; exit 0'
  fi
  echo "Provisioning ${NODE}"
  ssh -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no -i temp -A -p 22 ${SUDO_USER}@${NODE} 'sudo bash setup_datanode_all.sh > provision.log 2>&1; exit 0' &
done
wait
