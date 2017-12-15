#!/bin/bash
#
# yum install docker-1.12
set -e
yum install docker-1.12* -y

cat << EOF > /etc/docker/daemon.json
{"registry-mirrors": ["http://71b8d5d6.m.daocloud.io"],
    "insecure-registries":["192.168.3.150:5000"]
}
EOF

systemctl restart docker
