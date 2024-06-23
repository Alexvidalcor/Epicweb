#!/bin/bash

######### ** FOR WORKER NODE ** #########

hostnamectl set-hostname k8s-wrk-${worker_number}

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

# Turn off swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Enable bridge networking
modprobe br_netfilter
modprobe overlay
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Remove containerd config and restart it
rm /etc/containerd/config.toml
systemctl restart containerd

# Get EC2 instance IP
export ipaddr=$(ip address show eth0 | grep -Po 'inet \K[\d.]+')

# Wait for the master node to be ready
sleep 1m

# Download and execute the join command
aws s3 cp s3://${s3buckit_name}/join_command.sh /tmp/.
chmod +x /tmp/join_command.sh
bash /tmp/join_command.sh
