#!/bin/bash

echo 'Configuring gcs-connector'

set -e

#delete any existing gcs-connector jars
rm -f ${HADOOP_LIB_DIR}/gcs-connector*

#build our version of gcs-connector
wget https://github.com/zulily/bigdata-interop/archive/1.3.1-z.tar.gz
tar -zxf 1.3.1-z.tar.gz
rm 1.3.1-z.tar.gz

if [[ "$HADOOP_VERSION" = "1.x" ]]; then
 apache-maven-3.2.5/bin/mvn -DskipTests -P hadoop1 package -f bigdata-interop-1.3.1-z/pom.xml
 #copy the jar to hadoop libs
 cp bigdata-interop-1.3.1-z/gcs/target/gcs-connector-1.3.1-SNAPSHOT-shaded.jar ${HADOOP_LIB_DIR}/gcs-connector-1.3.1-z.jar
else
 apache-maven-3.2.5/bin/mvn -DskipTests -P hadoop2 package -f bigdata-interop-1.3.1-z/pom.xml
 #copy the jar to hadoop libs
 cp bigdata-interop-1.3.1-z/gcs/target/gcs-connector-1.3.1-SNAPSHOT-shaded.jar ${HADOOP_LIB_DIR}/gcs-connector-1.3.1-z.jar
fi
