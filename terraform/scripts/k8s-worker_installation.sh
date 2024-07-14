#!/bin/bash

######### ** FOR WORKER NODE ** #########

echo "-----------------------------"
echo "Setting hostname..."
hostnamectl set-hostname k8s-wrk-${worker_number}

echo "-----------------------------"
echo "Setting environment variables..."
echo export AWS_REGION=${region} >> /etc/profile

echo "-----------------------------"
echo "Configuring Kubernetes repository..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

echo "-----------------------------"
echo "Updating package manager and installing necessary packages..."
dnf update -y
dnf install -y kubelet kubeadm kubectl containerd

echo "-----------------------------"
echo "Enabling and starting containerd and kubelet..."
systemctl enable --now containerd
systemctl enable --now kubelet

echo "-----------------------------"
echo "Configuring containerd..."
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd

echo "-----------------------------"
echo "Waiting for  containerd and kubelet to be ready..."
sleep 1m

echo "-----------------------------"
echo "Turning off swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "-----------------------------"
echo "Retrieving EC2 instance IPs..."
ipaddr=$(ip address show ens5 | grep -Po 'inet \K[\d.]+')

echo "-----------------------------"
echo "Configuring sysctl for Kubernetes networking..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "-----------------------------"
echo "Waiting for the master node to be ready..."
sleep 5m

echo "-----------------------------"
echo "Downloading and executing the join command..."
aws s3 cp s3://${s3buckit_name}/join_command.sh /tmp/.
chmod +x /tmp/join_command.sh
bash /tmp/join_command.sh

echo "-----------------------------"
echo "Kubernetes worker setup is complete."