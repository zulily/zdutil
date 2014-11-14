#!/bin/bash

echo 'Configuring gcs-connector'

set -e

#delete any existing gcs-connector jars
rm -f ${HADOOP_LIB_DIR}/gcs-connector*

#build our version of gcs-connector
wget https://github.com/zulily/bigdata-interop/archive/1.3.1-z.tar.gz
tar -zxf 1.3.1-z.tar.gz
rm 1.3.1-z.tar.gz
bigdata-interop-1.3.1-z/tools/generate-poms.sh
apache-maven-3.2.3/bin/mvn -P hadoop1 package -f bigdata-interop-1.3.1-z/pom.xml-hadoop1

#copy the jar to hadoop libs
cp bigdata-interop-1.3.1-z/gcs/target/gcs-connector-1.3.1-SNAPSHOT-hadoop1-shaded.jar ${HADOOP_LIB_DIR}/
