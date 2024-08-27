#!/bin/bash

INSTANCE_IP=$1
SSH_PRIVATE_KEY=$2

ssh -o StrictHostKeyChecking=no -i $SSH_PRIVATE_KEY ec2-user@$INSTANCE_IP sudo -u ec2-user minikube start --driver=none
scp -i $SSH_PRIVATE_KEY ec2-user@$INSTANCE_IP:/home/ec2-user/.kube/config /home/jenkins/.kube2/config
scp -i $SSH_PRIVATE_KEY ec2-user@$INSTANCE_IP:/home/ec2-user/.minikube/profiles/minikube/client.crt /home/jenkins/.minikube2/client.crt
scp -i $SSH_PRIVATE_KEY ec2-user@$INSTANCE_IP:/home/ec2-user/.minikube/profiles/minikube/client.key /home/jenkins/.minikube2/client.key
scp -i $SSH_PRIVATE_KEY ec2-user@$INSTANCE_IP:/home/ec2-user/.minikube/ca.crt /home/jenkins/.minikube2/ca.crt

sed -i 's|/home/ec2-user/.minikube/profiles/minikube|/home/jenkins/.minikube2|g' /home/jenkins/.kube2/config
sed -i 's|/home/ec2-user/.minikube|/home/jenkins/.minikube2|g' /home/jenkins/.kube2/config