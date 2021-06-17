#  AKS reference architecture for Application *Containerization* (/Modernization) projects
This repository contains IaaC artifacts for deploying an AKS cluster to quickly jump-start new application modernization projects.

**Architecture Blueprint**

![alt tag](./images/dev-aks-cluster.PNG)

Use one of the options below to deploy the AKS Reference/Blueprint Architecture within your Azure Subscription.

## A. Deploy blueprint architecture using Azure CLI

1. Login to Azure on a terminal window

   Use [Azure cloud shell](https://shell.azure.com) or a terminal emulator and login to Azure with your credentials.

2. Clone this GitHub repository
   
   Clone this repository to your local machine (or Azure VM).  Then switch to the `dev-cluster` directory.

3. Review and update the deployment **Shell script**

   Review `./dev-cluster/azure-cli/deploy.sh` shell script and update variables with appropriate values (as needed).

4. Review and update the Linux Jumpbox/VM **Tools installation** script

   Review `./dev-cluster/azure-cli/install-script.sh`. (Optional) Use this script to add commands for installing additional tools/utilities on the Linux VM.

4. Provision Azure resources

   Finally, execute the shell script to provision Azure resources included in the blueprint architecture.  Refer to the command snippet below.

   ```bash
   # Run the shell script
   #
   $ ./dev-cluster/azure-cli/deploy.sh
   ```

## B. Deploy blueprint architecture using Azure Resource Manager (ARM) template

1. Login to Azure on a terminal window

   Use [Azure cloud shell](https://shell.azure.com) or a terminal emulator and login to Azure with your credentials.

2. Clone this GitHub repository

   Clone this repository to your local machine (or Azure VM).  Then switch to the `dev-cluster` directory.

3. Review and update the deployment **ARM template**

   Review the ARM template `./dev-cluster/arm-templates/template.json` and update it as needed.  Review file `./dev-cluster/arm-templates/parameters.json` and specify correct values for the various parameters.

4. Review and update the Linux Jumpbox/VM **Tools installation** script

   Review `./dev-cluster/azure-cli/install-script.sh`. (Optional) Use this script to add commands for installing additional tools/utilities on the Linux VM.

4. Provision Azure resources

   Finally, use Azure CLI to execute the ARM template. This will provision all Azure resources included in the reference architecture.  Refer to the command snippet below.

   ```bash
   # Remember to substitute correct values for parameters (exclude angle '<', '>' brackets!)
   #
   # Switch to the `arm-templates` sub-directory
   #
   $ cd ./dev-cluster/arm-templates
   #
   # Create a resource group to provision all resources
   # Location ~ Azure location should match the location where the resources will be deloyed
   #
   $ az group create --name <Resource-Group-Name> -l <Location>
   #
   # Execute the ARM template
   #
   $ az deployment group create --resource-group <Resource-Group-Name> --template-file template.json --parameters '@parameters.json'
   #
   ```

## Review deployed Azure resources

   Login to [Azure Portal](https://portal.azure.com) and verify all Azure resources have been provisioned ok.

   [Login to the Linux Jumpbox](https://docs.microsoft.com/en-us/azure/bastion/bastion-connect-vm-ssh) using Azure Bastion Host.  Verify *Azure CLI, Kubernetes CLI and Helm CLI* have been installed on the Jumpbox (virtual machine).  Refer to the commands below.

   ```bash
   # Verify Azure CLI is installed
   $ az --version
   #
   # Verify Kubernetes CLI is installed
   $ kubectl version
   #
   # Verify Helm CLI is installed
   $ helm version
   #
   # (Optional) Verify any additional tools which you might have installed ...
   #
   ```
