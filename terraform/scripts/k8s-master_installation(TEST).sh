#!/bin/bash

######### ** FOR MASTER NODE ** #########

hostname k8s-msr-1
echo "k8s-msr-1" > /etc/hostname

export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${private_key}
export AWS_DEFAULT_REGION=${region}

# Update package manager
dnf update -y

# Install Docker
dnf install docker
systemctl start docker
systemctl enable docker

# Install Kubernetes
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

# Install kubelet, kubeadm, and kubectl
yum install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

# Get EC2 instance IP
export ipaddr=$(ip address show eth0 | grep -Po 'inet \K[\d.]+')
export pubip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Configure containerd
rm /etc/containerd/config.toml
systemctl restart containerd

# Configure sysctl
cat <<EOF > /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Initialize Kubernetes cluster
kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/result.out
cat /tmp/result.out

# Configure kubectl
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chmod 755 /root/.kube/config

# Install and configure helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
bash get_helm.sh

# Install and configure flannel
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm repo add flannel https://flannel-io.github.io/flannel/
helm install flannel --set podCidr="192.168.0.0/16" --namespace kube
