#!/bin/bash

######### ** FOR MASTER NODE ** #########

echo "Setting hostname..."
hostnamectl set-hostname k8s-msr-1

echo "Setting environment variables..."
echo export AWS_REGION=${region} >> /etc/profile

echo "Configuring Kubernetes repository..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

echo "Updating package manager and installing necessary packages..."
dnf update -y
dnf install -y kubelet kubeadm kubectl containerd

echo "Enabling and starting containerd and kubelet..."
systemctl enable --now containerd
systemctl enable --now kubelet

echo "Turning off swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "Retrieving EC2 instance IPs..."
ipaddr=$(ip address show ens5 | grep -Po 'inet \K[\d.]+')
pubip=$(curl -s http://checkip.amazonaws.com)

echo "Restarting containerd with default configuration..."
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd

echo "Configuring sysctl for Kubernetes networking..."
cat <<EOF > /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "Initializing Kubernetes cluster..."
kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/kubeadm_init.log

echo "Configuring kubectl for ec2-user..."
mkdir -p /home/ec2-user/.kube
cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config
chmod 600 /home/ec2-user/.kube/config

echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Installing and configuring Flannel CNI plugin using Helm..."
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm repo add flannel https://flannel-io.github.io/flannel/
helm repo update
helm install my-flannel flannel/flannel --set podCidr="192.168.0.0/16" --namespace kube-flannel

echo "Kubernetes master setup is complete. Please check /tmp/kubeadm_init.log for initialization details."