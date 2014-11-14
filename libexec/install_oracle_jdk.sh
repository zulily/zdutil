#!/bin/bash

echo 'Installing Oracle JDK'

#install Oracle jdk 1.7
bash -c 'echo "deb http://cran.rstudio.com/bin/linux/debian lenny-cran/" >> /etc/apt/sources.list'
apt-get update
apt-get install -y java-package
wget -q --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u71-b14/jdk-7u71-linux-x64.tar.gz
echo y | su ${SUDO_USER} -c 'make-jpkg jdk-7u71-linux-x64.tar.gz'
dpkg -i oracle-j2sdk1.7_1.7.0+update71_amd64.deb
