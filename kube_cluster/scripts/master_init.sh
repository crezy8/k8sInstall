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
bash master_img.sh

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

# start kubelet service
systemctl start kubelet

# create cluster master
kubeadm init --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.8.5 --skip-preflight-checks

# set environment
if ! [ -d  $HOME/.kube ]; then
	mkdir -p $HOME/.kube
fi

cp -f -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# create flannel network plugin
kubectl apply -f ../conf/manifests/kube-flannel-rbac.yml
kubectl apply -f ../conf/manifests/kube-flannel.yml

