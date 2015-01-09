ENV = '''
#!/bin/bash

export CONFIGBUCKET=$CONFIGBUCKET
export NAMENODE_HOSTNAME=$NAMENODE_HOSTNAME
export PREFIX=$PREFIX
export NUM_WORKERS=$NUM_WORKERS
export DEFAULT_FS=$DEFAULT_FS
export SETUP_SQUID=$SETUP_SQUID
export BDCONFIG=$BDCONFIG
export PROJECT=$PROJECT
export INSTALL_ORACLE_JDK=$INSTALL_ORACLE_JDK
export INSTALL_JAVA=$INSTALL_JAVA
export HADOOP_VERSION=$HADOOP_VERSION

export HADOOP_TMP_DIR=/hadoop/tmp
export NAMENODE_URI=hdfs://$${NAMENODE_HOSTNAME}:8020/
export ENABLE_HDFS_PERMISSIONS=false
export JOB_TRACKER_URI=$${NAMENODE_HOSTNAME}:9101
export JAVAOPTS='-Xms1024m -Xmx2048m'

export HADOOP_INSTALL_DIR='/home/hadoop/hadoop-install'

export HADOOP_LIB_DIR="$${HADOOP_INSTALL_DIR}/lib"

if [[ "$${DEFAULT_FS}" == "hdfs" ]]; then
    export ENABLE_HDFS=1
fi

STAGING_DIR_BASE="gs://$${CONFIGBUCKET}/bdutil-staging"
export BDUTIL_GCS_STAGING_DIR="$${STAGING_DIR_BASE}/$${NAMENODE_HOSTNAME}"

if [[ "$$HADOOP_VERSION" = "1.x" ]]; then
 export HADOOP_TARBALL_URI=http://www.apache.org/dist/hadoop/core/hadoop-1.2.1/hadoop-1.2.1.tar.gz
 export HADOOP_CONF_DIR="$${HADOOP_INSTALL_DIR}/conf"
else
 export HADOOP_TARBALL_URI=http://www.apache.org/dist/hadoop/core/hadoop-2.5.2/hadoop-2.5.2.tar.gz
 export HADOOP_CONF_DIR="$${HADOOP_INSTALL_DIR}/etc/hadoop"
fi

'''