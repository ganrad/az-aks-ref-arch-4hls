/*
 * Author: Ganesh Radhakrishnan
 * Email: ganrad01@gmail.com
 * Date: 06-17-2021
 * Description: Module for provisioning an AKS cluster. 
 * Notes:
 * - Latest stable version of AKS cluster will be deployed
 */

// Parameters
param location string
param vnet_subnet_id string
param aks_cluster_name string
param aks_dns_prefix string = 'k8slab00'
@minValue(1)
param aks_node_count int
@allowed([
  'azure'
  'kubenet'
])
param aks_cni_plugin string = 'azure'
param aks_service_cidr string
param aks_dns_service_ip string
param aks_pod_cidr string
@minValue(1)
param aks_node_count_min int
@maxValue(100)
param aks_node_count_max int
param aks_node_vm_size string
param aks_node_osdisk_type string
@minValue(30)
param aks_node_osdisk_size int
param aks_res_tags object = {}
param aks_nodepool_tags object = {}
param aks_nodepool_labels object = {}
@allowed([
  ''
  'azure'
  'calico'
])
@description('AKS Network Policy is disabled by default')
param aks_network_policy string = ''
@allowed([
  'basic'
  'standard'
])
param aks_load_balancer_sku string
@minValue(1)
param aks_lb_outbound_ips int = 1
param aks_lb_outbound_ports int = 0
@minValue(4)
@maxValue(30)
@description('Azure Load Balancer idle timeout in minutes.  Default is 30 mins')
param aks_lb_idle_timeout_mins int = 30
@allowed([
  'loadBalancer'
  'userDefinedRouting'
])
param aks_outbound_type string = 'loadBalancer'
@minValue(30)
@maxValue(250)
param aks_max_pods int
param aks_private_cluster bool = false
param aks_authorized_ips array = []
param aks_nodepool_linux_profile object = {}
// Imp: Windows nodepools can only be added when using azure CNI plug-in
param aks_nodepool_windows_profile object = {}
param aks_nodepool_addon_profile object = {}

// Resources
resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-03-01' = {
  name: aks_cluster_name
  location: location
  tags: empty(aks_res_tags) ? json('null') : aks_res_tags
  sku: {
    name: 'Basic'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aks_dns_prefix
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool1'
        count: aks_node_count
        vmSize: aks_node_vm_size
        osDiskSizeGB: aks_node_osdisk_size
        osDiskType: aks_node_osdisk_type
        kubeletDiskType: 'OS'
        vnetSubnetID: vnet_subnet_id
        maxPods: aks_max_pods
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        maxCount: aks_node_count_max
        minCount: aks_node_count_min
        enableAutoScaling: true
        tags: empty(aks_nodepool_tags) ? json('null') : aks_nodepool_tags
        nodeLabels: empty(aks_nodepool_labels) ? json('null') : aks_nodepool_labels
        enableEncryptionAtHost: false
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        enableFIPS: false
      }
    ]
    addonProfiles: empty(aks_nodepool_addon_profile) ? json('null') : aks_nodepool_addon_profile
    networkProfile: {
      networkPlugin: aks_cni_plugin
      networkPolicy: empty(aks_network_policy) ? json('null') : aks_network_policy
      loadBalancerSku: aks_load_balancer_sku
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: aks_lb_outbound_ips
        }
        allocatedOutboundPorts: aks_lb_outbound_ports
        idleTimeoutInMinutes: aks_lb_idle_timeout_mins
      }
      podCidr: aks_cni_plugin == 'kubenet' ? aks_pod_cidr : json('null')
      serviceCidr: aks_service_cidr
      dnsServiceIP: aks_dns_service_ip
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: aks_outbound_type
    }
    apiServerAccessProfile: {
      authorizedIPRanges: aks_private_cluster ? [] : aks_authorized_ips
      enablePrivateCluster: aks_private_cluster
    }
    linuxProfile: (!empty(aks_nodepool_linux_profile) ? aks_nodepool_linux_profile : json('null'))
    windowsProfile: (!empty(aks_nodepool_windows_profile) ? aks_nodepool_windows_profile : json('null'))
  }
}
