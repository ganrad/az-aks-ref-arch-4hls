#
#
#
#
#---------------------------------------------------
# Variables
#---------------------------------------------------
#
LOCATION="westus"
RESOURCE_GROUP="csu-dev-grts-dc"

# Virtual network and subnets
VNET_NAME="devVnet"
VNET_ADDRESS_CIDR="192.168.0.0/16"
SERVICES_SUBNET_NAME="services-subnet"
SERVICES_SUBNET_CIDR="192.168.1.0/24"
BASTION_SUBNET_NAME="AzureBastionSubnet"
BASTION_SUBNET_CIDR="192.168.2.0/24"
AKS_SUBNET_NAME="aks-subnet"
AKS_SUBNET_CIDR="192.168.3.0/24"

# Azure VM's
JUMP_VM_NAME="k8s-lab-vm"
JUMP_VM_NIC_NAME="k8s-lab-vm-nic"
JUMP_VM_IMAGE="Debian:debian-10:10:latest"
JUMP_VM_SIZE="Standard_B2s"
JUMP_VM_DISK_SIZE=128
JUMP_VM_ADMIN_UNAME="labuser"
JUMP_VM_ADMIN_PWD="azk8sLab2021!"

# Bastion host
BASTION_HOST_NAME="bastionHost"
BASTION_HOST_PIP_NAME="bastionPublicIP"
#---------------------------------------------------
# Script
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
  --name toolsScript \
  --resource-group $RESOURCE_GROUP \
  --vm-name $JUMP_VM_NAME \
  --publisher Microsoft.Azure.Extensions \
  --settings ./script-config.json

az vm extension list \
  -g $RESOURCE_GROUP \
  --vm-name $JUMP_VM_NAME
echo -e "Updated jump-box [$JUMP_VM_NAME] with pre-requisite tools - Azure CLI, k8s CLI & Helm CLI\n"

echo -e "Finished deploying AKS dev cluster environment"
