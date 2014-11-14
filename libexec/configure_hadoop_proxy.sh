#!/bin/bash

echo 'Configuring hadoop proxy'

set -e

bdconfig set_property \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --name 'fs.gs.proxy.host' \
    --value ${PREFIX}-nn \
    --create_if_absent \
    --clobber

bdconfig set_property \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --name 'fs.gs.proxy.port' \
    --value '3128' \
    --create_if_absent \
    --clobber

