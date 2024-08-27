#!/bin/bash

# Actualizar el sistema
sudo yum update -y

# Instalación de dependencias de red
sudo yum install -y docker conntrack socat ebtables ethtool  
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

# Instalar kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Instalar minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Instalar cri-dockerd
sudo yum install -y git golang
git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
sudo mkdir -p /usr/local/bin/
mkdir bin
go mod tidy
go mod vendor
go build -o bin/cri-dockerd || { echo 'Build failed'; exit 1; }
sudo cp bin/cri-dockerd /usr/local/bin/
sudo cp packaging/systemd/cri-docker.service /etc/systemd/system/
sudo cp packaging/systemd/cri-docker.socket /etc/systemd/system/
sudo sed -i -e 's|/usr/bin/cri-dockerd|/usr/local/bin/cri-dockerd|g' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
sudo systemctl start cri-docker.service

# Instalar crictl
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.30.0/crictl-v1.30.0-linux-amd64.tar.gz
sudo tar -C /usr/local/bin -xzf crictl-v1.30.0-linux-amd64.tar.gz || { echo 'Failed to extract crictl'; exit 1; }
rm -rf crictl-v1.30.0-linux-amd64.tar.gz

# Instalar CNI plugins
sudo mkdir -p /opt/cni/bin
sudo curl -Lo /opt/cni/bin/cni-plugins-linux-amd64-v1.3.0.tgz https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo tar -xzvf /opt/cni/bin/cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin/
sudo rm -rf /opt/cni/bin/cni-plugins-linux-amd64-v1.3.0.tgz

# Descargar e instalar kubectl correcto
curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Iniciar Minikube
sudo -u ec2-user minikube start --driver=none

# Configurar permisos
sudo mkdir -p /home/ec2-user/.kube /home/ec2-user/.minikube
[ -d /root/.kube ] && sudo mv /root/.kube /home/ec2-user/.kube || echo '/root/.kube not found, skipping'
[ -d /root/.minikube ] && sudo mv /root/.minikube /home/ec2-user/.minikube || echo '/root/.minikube not found, skipping'
sudo chmod +x /usr/local/bin/cri-dockerd
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube /home/ec2-user/.minikube
sudo -u ec2-user minikube start --driver=none