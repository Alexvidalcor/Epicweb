#!/bin/bash

######### ** FOR MASTER NODE ** #########

echo "-----------------------------"
echo "Setting hostname..."
# Update hostname as necessary
hostnamectl set-hostname k8s-master

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
echo "Waiting for containerd and kubelet to be ready..."
sleep 1m

echo "-----------------------------"
echo "Turning off swap..."
swapoff -a
sed -i '/swap/d' /etc/fstab

echo "-----------------------------"
echo "Retrieving EC2 instance IPs..."
ipaddr=$(ip address show ens5 | grep -Po 'inet \K[\d.]+')
pubip=$(curl -s http://checkip.amazonaws.com)

echo "-----------------------------"
echo "Configuring sysctl for Kubernetes networking..."
cat <<EOF > /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "-----------------------------"
echo "Initializing Kubernetes cluster..."
kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/kubeadm_init.log

echo "-----------------------------"
echo "Configuring kubectl for root..."
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown root:root /root/.kube/config
chmod 600 /root/.kube/config
echo export KUBECONFIG=/root/.kube/config >> /etc/profile

echo "-----------------------------"
echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "-----------------------------"
echo "Installing and configuring Flannel CNI plugin using Helm..."
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm repo add flannel https://flannel-io.github.io/flannel/
helm repo update
helm install my-flannel flannel/flannel --set podCidr="192.168.0.0/16" --namespace kube-flannel

echo "-----------------------------"
echo "Kubernetes master setup is complete. Please check /tmp/kubeadm_init.log for initialization details."

echo "-----------------------------"
echo "Creating joining command for workers..."
kubeadm_join_command=$(grep -E 'kubeadm join .+ --token .+|discovery-token-ca-cert-hash sha256' /tmp/kubeadm_init.log | sed -z 's/\\\n//g')

# Check if the join command has the expected structure
if [[ $kubeadm_join_command =~ kubeadm\ join.*\ --token\ [a-z0-9]{6}\.[a-z0-9]{16}.*discovery-token-ca-cert-hash\ sha256:[a-f0-9]{64} ]]; then
    echo "Join command is valid:"
    echo $kubeadm_join_command

    # Send the join command to AWS SSM Parameter Store as a SecureString
    aws ssm put-parameter --name "kubeadm_join_command" \
                          --value "$kubeadm_join_command" \
                          --type SecureString \
                          --overwrite
    if [ $? -eq 0 ]; then
        echo "Join command successfully stored in AWS SSM Parameter Store."
    else
        echo "Error: Failed to store join command in AWS SSM Parameter Store."
        exit 1
    fi
else
    echo "Error: Invalid kubeadm join command structure."
    exit 1
fi

