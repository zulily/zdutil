#!/bin/bash

if [[ ${INSTALL_ORACLE_JDK} == "true" ]]; then
  bash install_oracle_jdk.sh
else
  bash install_openjdk.sh
fi
