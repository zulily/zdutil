#!/bin/bash

echo 'Setting up squid'

apt-get update
apt-get install -y squid3

# Enable any machine on the local network to use the Squid3 server
sed -i 's:#\(http_access allow localnet\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(http_access deny to_localhost\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(acl localnet src 10.0.0.0/8.*\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(acl localnet src 172.16.0.0/12.*\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(acl localnet src 192.168.0.0/16.*\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(acl localnet src fc00\:\:/7.*\):\1:' /etc/squid3/squid.conf
sed -i 's:#\(acl localnet src fe80\:\:/10.*\):\1:' /etc/squid3/squid.conf

service squid3 restart
