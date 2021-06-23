#  Azure Kubernetes Service (AKS) reference architectures
The main goal of this repository is to compile infrastructure as code (IaaC) scripts and document the steps for automating the installation and configuration of proven AKS reference architectures (aka Blueprints).  The reference architecture implementations provide a secure, reliable and highly available container platform for running mission critical applications and are primarily targeted towards Healthcare customers.

Each sub-project described below contains IaaC artifacts (Bicep script, ARM template, Shell script) for automating the provisioning and configuration of the respective AKS reference (/blueprint) architecture.

- [Deploy an AKS cluster to jump-start new application modernization projects](./dev-cluster)
  This sub-project describes the steps for deploying an AKS cluster in a sandbox Azure subscription. Use the automation scripts to quickly standup a fully functional Kubernetes cluster for implementing **MVPs/PoCs/Pilots** and jump-start application containerization / modernization projects.

- [Deploy a private AKS cluster within a VNET for deploying Production workloads](./private-cluster)
  This sub-project describes the steps for deploying a production grade private AKS cluster within a secure virtual network. The standard Azure Load Balancer which front ends the AKS ingress controller (Nginx) is configured with a private front end IP address & is not accessible via the internet.  The Kubernetes (AKS) API server is exposed via a private endpoint and is only accessible from within the AKS VNET.  An private Azure Container Registry (ACR) instance is also deployed within a separate subnet in the VNET.  The AKS cluster is configured to only pull images from this private ACR instance.
