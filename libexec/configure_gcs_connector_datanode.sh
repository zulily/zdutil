#!/bin/bash

echo 'Configuring gcs-connector'

set -e

#delete any existing gcs-connector jars
rm -f ${HADOOP_LIB_DIR}/gcs-connector*

#copy the jar to hadoop libs
cp gcs-connector-1.3.1-z.jar ${HADOOP_LIB_DIR}/
