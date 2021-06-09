#
# Author: Ganesh Radhakrishnan@Microsoft
# Email: ganrad01@gmail.com
# Date: 06-09-2021
# Description: Use this script to provision a 'dev' AKS cluster
# Notes:
#
#---------------------------------------------------
# Variables
#---------------------------------------------------
#
LOCATION="westus"
RESOURCE_GROUP="csu-dev-grts-dc"

# ***** Virtual network and subnets
VNET_NAME="devVnet"
VNET_ADDRESS_CIDR="192.168.0.0/16"
SERVICES_SUBNET_NAME="services-subnet"
SERVICES_SUBNET_CIDR="192.168.1.0/24"
BASTION_SUBNET_NAME="AzureBastionSubnet"
BASTION_SUBNET_CIDR="192.168.2.0/24"
AKS_SUBNET_NAME="aks-subnet"
AKS_SUBNET_CIDR="192.168.3.0/24"

# ***** Azure VM's
JUMP_VM_NAME="k8s-lab-vm"
JUMP_VM_NIC_NAME="k8s-lab-vm-nic"
JUMP_VM_IMAGE="Debian:debian-10:10:latest"
JUMP_VM_SIZE="Standard_B2s"
JUMP_VM_DISK_SIZE=128
JUMP_VM_ADMIN_UNAME="labuser"
JUMP_VM_ADMIN_PWD="azk8sLab2021!"

# ***** Bastion host
BASTION_HOST_NAME="bastionHost"
BASTION_HOST_PIP_NAME="bastionPublicIP"

# ***** Azure Container Registry 
# ACR name must be unique and can contain 5-50 alphanumeric characters
ACR_NAME="k8sdevRegistry01"
# SKU = Basic, Standard, Premium
ACR_SKU="Standard"

# ***** Azure Kubernetes Service
AKS_NAME="k8sdevlab"
AKS_NODE_COUNT=3
AKS_CNI_PLUGIN="kubenet"
AKS_SERVICE_CIDR="10.0.0.0/16"
AKS_DNS_SERVICE_IP="10.0.0.10"
# Pod cidr is only needed for 'kubenet' CNI plug-in
# If using Azure CNI plug-in remember to update the AKS create command below
AKS_POD_CIDR="10.244.0.0/16"
AKS_NODE_COUNT_MIN=3
AKS_NODE_COUNT_MAX=5
AKS_NODE_VM_SIZE="Standard_DS2_v2"
# Use OS disk type 'Ephemeral' for low read/write latency (/io)
AKS_NODE_OS_DISK_TYPE="Ephemeral"
# Disk size is in GB
AKS_NODE_OS_DISK_SIZE="60"
AKS_TAGS="env=lab unit=cloud"
AKS_NODEPOOL_TAGS="env=lab unit=cloud"
# (Optional) For cluster with Windows and Linux nodepools, specify Windows user name and password
AKS_WIN_ADM_UNAME="admin"
AKS_WIN_ADM_PWD="Password2021!"
AKS_LOAD_BALANCER_SKU="standard"
# Always overcommit the no. of pods / node
AKS_MAX_PODS=60

#---------------------------------------------------
# ***** Script
#---------------------------------------------------

## Exit when any command fails
set -e

az group create --name $RESOURCE_GROUP --location $LOCATION
echo -e "Azure resource group [$RESOURCE_GROUP] created\n"

az network vnet create --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --name $VNET_NAME \
  --address-prefixes $VNET_ADDRESS_CIDR \
  --subnet-name $SERVICES_SUBNET_NAME \
  --subnet-prefix $SERVICES_SUBNET_CIDR
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME --query id -o tsv)
echo -e "Azure virtual network [$VNET_NAME] created\n"

az network nic create \
  --resource-group $RESOURCE_GROUP \
  --name $JUMP_VM_NIC_NAME \
  --location $LOCATION \
  --subnet $SERVICES_SUBNET_NAME \
  --vnet-name $VNET_NAME
echo -e "Azure VM nic [$JUMP_VM_NIC_NAME] created\n"

az vm create --resource-group $RESOURCE_GROUP \
  --name $JUMP_VM_NAME \
  --image $JUMP_VM_IMAGE \
  --size $JUMP_VM_SIZE \
  --data-disk-sizes-gb $JUMP_VM_DISK_SIZE \
  --generate-ssh-keys \
  --location $LOCATION \
  --admin-username $JUMP_VM_ADMIN_UNAME \
  --admin-password $JUMP_VM_ADMIN_PWD \
  --authentication-type password \
  --nics $JUMP_VM_NIC_NAME
echo -e "Linux jump-box [$JUMP_VM_NAME] created\n"

az network public-ip create --resource-group $RESOURCE_GROUP \
  --name $BASTION_HOST_PIP_NAME \
  --sku Standard \
  --location $LOCATION
echo -e "Bastion host public IP [$BASTION_HOST_PIP_NAME] created\n"

az network vnet subnet create --name $BASTION_SUBNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes $BASTION_SUBNET_CIDR
echo -e "Bastion subnet [$BASTION_SUBNET_NAME] created\n"

az network bastion create --name $BASTION_HOST_NAME \
  --public-ip-address $BASTION_HOST_PIP_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --location $LOCATION
echo -e "Bastion service [$BASTION_HOST_NAME] created\n"

az vm extension set \
  --name customScript \
  --resource-group $RESOURCE_GROUP \
  --vm-name $JUMP_VM_NAME \
  --publisher Microsoft.Azure.Extensions \
  --settings ./script-config.json

az vm extension list \
  -g $RESOURCE_GROUP \
  --vm-name $JUMP_VM_NAME
echo -e "Updated jump-box [$JUMP_VM_NAME] with pre-requisite tools - Azure CLI, k8s CLI & Helm CLI\n"

az acr create --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku $ACR_SKU
echo -e "ACR [$ACR_NAME] created\n"

az network vnet subnet create --name $AKS_SUBNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --address-prefixes $AKS_SUBNET_CIDR
AKS_SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $AKS_SUBNET_NAME --query id -o tsv)
echo -e "AKS subnet [$AKS_SUBNET_NAME] created\n"

# Provision AKS with latest stable version
az aks create --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count $AKS_NODE_COUNT \
  --network-plugin $AKS_CNI_PLUGIN \
  --service-cidr $AKS_SERVICE_CIDR \
  --dns-service-ip $AKS_DNS_SERVICE_IP \
  --pod-cidr $AKS_POD_CIDR \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $AKS_SUBNET_ID \
  --enable-managed-identity \
  --enable-cluster-autoscaler \
  --min-count $AKS_NODE_COUNT_MIN \
  --max-count $AKS_NODE_COUNT_MAX \
  --node-vm-size $AKS_NODE_VM_SIZE \
  --node-osdisk-type $AKS_NODE_OS_DISK_TYPE \
  --node-osdisk-size $AKS_NODE_OS_DISK_SIZE \
  --tags $AKS_TAGS \
  --nodepool-tags $AKS_NODEPOOL_TAGS \
  --windows-admin-username $AKS_WIN_ADM_UNAME \
  --windows-admin-password $AKS_WIN_ADM_PWD \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku $AKS_LOAD_BALANCER_SKU \
  --max-pods $AKS_MAX_PODS \
  --attach-acr $ACR_NAME \
  --enable-addons http_application_routing,monitoring \
  --zones 1 2 3
echo -e "AKS [$AKS_NAME] created\n"

echo -e "Finished deploying AKS dev cluster environment"
