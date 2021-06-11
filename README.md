#  Reference Architectures for Azure Kubernetes Services (AKS) production deployments
The primary goal of this repository is to document and capture IaaC deployment artifacts for AKS reference architectures.

- [Deploy a dev cluster](./dev-cluster)
  This project contains artifacts for deploying and configuring an AKS cluster in a sandbox Azure subscription. The automation scripts will help your teams quickly standup a fully functional **development** Kubernetes cluster and jump start containerization / application modernization projects.
- [Deploy a private cluster](./private-cluster)
  This project contains the artifacts for deploying an AKS cluster within an Azure private virtual network (VNET) subnet.  The standard Azure Load Balancer which front ends the AKS ingress controller (Nginx) is configured with a private front end IP address & is not accessible via the internet.  The Kubernetes (AKS) API server is exposed only via a private endpoint and is only accessible from within the AKS VNET.  An private Azure Container Registry (ACR) instance is also deployed within a separate subnet in the VNET and the AKS cluster is configured to only pull images from this private ACR instance.
