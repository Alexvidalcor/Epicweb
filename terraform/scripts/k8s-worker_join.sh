#!/bin/bash

# This is a hypothetical join command script for a Kubernetes cluster

# Replace this with the actual join command you get from kubeadm init on the master node
JOIN_COMMAND="kubeadm join --token <token> <master-node-ip>:<master-node-port> --discovery-token-ca-cert-hash sha256:<hash>"

# Run the join command
$JOIN_COMMAND