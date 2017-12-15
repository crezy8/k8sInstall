#!/bin/bash
#
# create a kuberbetes node

set -e
rpm="kubelet kubeadm kubectl kubernetes-cni"
# install rpm package
if ! rpm -q $rpm; then
	yum install -y ../rpm/*.rpm
fi
# set kubelet service config
cp ../conf/kubeadm/*.conf /etc/systemd/system/kubelet.service.d/
systemctl enable kubelet
systemctl daemon-reload

# cp cni bin
cp ../bin/portmap /opt/cni/bin/

# pull imgs
bash node_img.sh

# set host network
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# clean network interface
if ip link show | grep -q "[0-9]\+: flannel.[0-9]"; then
        flannel=`ip link show | grep -o "[0-9]\+: flannel.[0-9]" | awk '{print $2}'`
        echo "delete interface $flannel"
	ip link del $flannel
fi

if ip link show | grep -q "[0-9]\+: cni[0-9]"; then
        cni=`ip link show | grep -o "[0-9]\+: cni[0-9]" | awk '{print $2}'`
        echo "delete interface $cni"
	ip link del $cni
fi
# kube init
kubeadm reset
sleep 10

kubeadm join --token b2d436.49443e4ef71b0736 192.168.3.183:6443 --discovery-token-ca-cert-hash sha256:e847fbe442d6217e84c598895938d4b69552498026d21a30b2fda56e6fabeaa4

# start kubelet service
systemctl start kubelet
