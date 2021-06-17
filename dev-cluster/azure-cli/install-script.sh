#!/bin/bash
#
# --------------------------------------------------------
# Author: Ganesh Radhakrishnan@Microsoft
# Email : ganrad01@gmail.com
# Date : 06-09-2021
# Description: Use this script to install tools/utilities etc on the Linux jump-box
# Notes:
# --------------------------------------------------------

set -e
echo -e "***** Script execution started *****\n"

(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc

sudo mkfs -t ext4 /dev/sdc1

sudo mkdir -p $1 && sudo mount /dev/sdc1 $1

UUID=$(sudo blkid -s UUID -o value /dev/sdc1)

echo "UUID=$UUID	$1	ext4	defaults,nofail	1	2" | sudo tee -a /etc/fstab

echo -e "***** Formatted disk and mounted file system @ [$1] *****\n"

# Install Git
sudo apt-get install -y git
echo -e "***** Installed Git *****\n"

# Install Azure CLI (this method is prone to throwing exceptions !!)
#curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

sudo apt-get update
sudo apt-get -y install ca-certificates curl apt-transport-https lsb-release gnupg

curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-get update
sudo apt-get install azure-cli
echo -e "***** Installed Azure CLI *****\n"

# Install Helm (Living on the edge ...)
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
echo -e "***** Installed Helm CLI *****\n"

# Install Kubernetes CLI (Latest version)
sudo curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && sudo chmod 755 /usr/local/bin/kubectl
echo -e "***** Installed Kubernetes CLI *****\n"

# Install additional tools as required (below) eg., docker engine, Istio service mesh etc

echo -e "***** Script execution finished *****\n"

