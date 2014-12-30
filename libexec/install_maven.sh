#!/bin/bash

echo 'Installing maven'

set -e

#install maven
wget http://www.us.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
tar -zxf apache-maven-3.2.5-bin.tar.gz
rm apache-maven-3.2.5-bin.tar.gz
