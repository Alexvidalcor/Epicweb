#!/bin/bash

######### ** FOR WORKER NODE ** #########

echo "Setting hostname..."
hostnamectl set-hostname k8s-wrk-${worker_number}

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
dnf install -y kubelet kubeadm kubectl

echo "Enabling and starting containerd and kubelet..."
systemctl enable --now containerd
systemctl enable --now kubelet

echo "Turning off swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "Retrieving EC2 instance IPs..."
ipaddr=$(ip address show ens5 | grep -Po 'inet \K[\d.]+')

echo "Restarting containerd with default configuration..."
rm /etc/containerd/config.toml
systemctl restart containerd

echo "Configuring sysctl for Kubernetes networking..."
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "Waiting for the master node to be ready..."
sleep 5m

echo "Downloading and executing the join command..."
aws s3 cp s3://${s3buckit_name}/join_command.sh /tmp/.
chmod +x /tmp/join_command.sh
bash /tmp/join_command.sh

echo "Kubernetes worker setup is complete."


#!/bin/bash

######### ** JOIN WORKER TO KUBERNETES CLUSTER ** #########

# echo "Retrieving join details from S3..."
# # You would replace these with actual values or parameterize them as needed.
# master_ip=${master_ip}
# token=${token}
# ca_cert_hash=${ca_cert_hash}

# echo "Joining the Kubernetes cluster..."
# kubeadm join ${master_ip}:6443 --token ${token} --discovery-token-ca-cert-hash ${ca_cert_hash}

# echo "Kubernetes worker node successfully joined the cluster."