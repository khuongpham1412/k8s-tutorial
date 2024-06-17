#!/bin/bash
DOCKER_REPO=https://download.docker.com/linux/centos/docker-ce.repo
# step 1:
sudo yum update -y

# step 2: install package nessecery
sudo yum install ca-certificates curl

# step 3: install docker
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo $DOCKER_REPO
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# start docker
sudo systemctl start docker

# step 4: setup cri-docker as container runtime interface (CRI)
cd Downloads/
sudo rpm -i cri-dockerd-0.3.14-3.el7.x86_64.rpm
sudo systemctl daemon-reload
sudo systemctl enable --now cri-docker.socket
sudo systemctl status cri-docker.socket

# step 4: install kubernetes
# Enable IPv4 packet forwarding
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
sudo sysctl net.ipv4.ip_forward

# disable swap
sudo swapoff -a

# turn off SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# install kubeadm, kubelet
sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# stop firewalld
sudo systemctl stop firewalld