#!/bin/bash
#-----------------------------------------------------
#
#
#
# Install pre-requisite tools on the Linux Jump-box.
#-----------------------------------------------------
set -e
echo -e "Starting script execution\n"

# Format the extra hard disk and mount the file system on /opt/local

(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc

sudo mkfs -t ext4 /dev/sdc1

sudo mkdir -p /opt/local && sudo mount /dev/sdc1 /opt/local

UUID=$(sudo blkid -s UUID -o value /dev/sdc1)

echo "UUID=$UUID	/opt/local	ext4	defaults,nofail	1	2" | sudo tee -a /etc/fstab

echo -e "Formatted disk and mounted file system\n"

# Install Git
sudo apt-get install -y git
echo -e "Installed Git\n"

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
echo -e "Installed Azure CLI\n"

# Install Helm (Living on the edge ...)
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo -e "Installed Helm CLI\n"

# Install Kubernetes CLI (Latest version)
sudo curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && sudo chmod 755 /usr/local/bin/kubectl
echo -e "Installed Kubernetes CLI\n"

echo -e "Script finished execution!"

