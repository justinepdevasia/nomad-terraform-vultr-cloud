#!/usr/bin/env bash
set -e

# Disable interactive apt prompts
export DEBIAN_FRONTEND=noninteractive

NOMAD_VERSION="${NOMAD_VERSION:-1.7.3}"
CNI_VERSION="${CNI_VERSION:-v1.3.0}"

# Update packages
sudo apt-get -y update
# Install software-properties-common
sudo apt-get install -y software-properties-common

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
# Add HashiCorp repository
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
# Update packages again
sudo apt-get -y update

# Install Nomad
sudo apt-get install -y nomad="${NOMAD_VERSION}"-1


# Disable the firewall
sudo ufw disable || echo "ufw not installed"

sudo apt-get -y update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  
  # Create daemon.json if it doesn't exist
if [ ! -f /etc/docker/daemon.json ]; then
    sudo touch /etc/docker/daemon.json
fi

  # Restart Docker
sudo systemctl restart docker
sudo usermod -aG docker ubuntu

# Download and install CNI plugins
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-$([ "$(uname -m)" = aarch64 ] && echo arm64 || echo amd64)-${CNI_VERSION}".tgz &&
  sudo mkdir -p /opt/cni/bin &&
  sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
