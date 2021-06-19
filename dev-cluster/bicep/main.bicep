/*
* Author : Ganesh Radhakrishnan
* Email : ganrad01@gmail.com
* Date : 06-17-2021
* Description: This Bicep template provisions resources included in the AKS blueprint architecture
* Notes:
*/

// Parameters
param devVnet_name string = 'spokeVnet'
param devVnet_addr_cidr string = '192.168.0.0/16'
param devVnet_services_subnet_name string = 'services-subnet'
param devVnet_services_subnet_cidr string = '192.168.1.0/24'
param devVnet_aks_subnet_name string = 'aks-subnet'
param devVnet_aks_subnet_cidr string = '192.168.2.0/24'
param jump_vm_name string = 'k8s-lab-vm'
param jump_vm_nic_name string = 'k8s-lab-vm-nic'
param jump_vm_image object = {
  publisher: 'Debian'
  offer: 'debian-10'
  sku: '10'
  version: 'latest'
}
param jump_vm_size string = 'Standard_B2s'
param jump_vm_disk_size int = 128
@description('Location/URL of the Jumbox (VM) install script')
param install_script_location string = 'https://raw.githubusercontent.com/ganrad/az-aks-ref-arch-4hls/main/dev-cluster/azure-cli/install-script.sh'
@description('Install script to execute on the jump box VM')
param install_script_command string = 'install-script.sh'
@description('File system directory to mount the additional disk')
param install_script_arg1 string = '/opt/local'
param jump_vm_admin_uname string = 'labuser'
@secure()
param jump_vm_admin_pwd string
param hubVnet_name string = 'hubVnet'
param hubVnet_addr_cidr string = '192.169.0.0/16'
param hubVnet_bastion_subnet_name string = 'AzureBastionSubnet'
param hubVnet_bastion_subnet_cidr string = '192.169.1.0/27'
param bastion_host_name string = 'bastionHost'
param bastion_host_pip_name string = 'bastionPublicIP'
param bastion_host_dns_name string = 'testbastion00'
param acr_name string = 'k8sdevRegistry00'
param acr_sku string = 'Standard'
param aks_cluster_name string = 'k8sdevlab'
param aks_dns_prefix string = 'k8sdevlab'
param aks_node_count int = 3
param aks_cni_plugin string = 'kubenet'
param aks_service_cidr string = '10.0.0.0/16'
param aks_dns_service_ip string = '10.0.0.10'
param aks_pod_cidr string = '10.244.0.0/16'
param aks_node_count_min int = 3
param aks_node_count_max int = 5
param aks_node_vm_size string = 'Standard_DS2_v2'
param aks_node_osdisk_type string = 'Ephemeral'
param aks_node_osdisk_size int = 60
param aks_nodepool_tags object = {
  env: 'lab'
  unit: 'cloud-engineering'
}
param aks_windows_adm_uname string = 'azureuser'
@description('Windows password must be min. of 14 chars. Must have 3 of these - lowercase, uppercase, special char or digit')
param aks_windows_adm_pwd string = '${uniqueString(resourceGroup().id, 'winadmin')}1L'
param aks_load_balancer_sku string = 'standard'
param aks_max_pods int = 110

// Resources
resource spokeVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: devVnet_name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        devVnet_addr_cidr
      ]
    }
    subnets: [
      {
        name: devVnet_aks_subnet_name
        properties: {
          addressPrefix: devVnet_aks_subnet_cidr
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: devVnet_services_subnet_name
        properties: {
          addressPrefix: devVnet_services_subnet_cidr
        }
      }
    ]
  }
}

resource jumpVMNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: jump_vm_nic_name
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spokeVirtualNetwork.properties.subnets[1].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource jumpVM 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: jump_vm_name
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: jump_vm_size
    }
    osProfile: {
      computerName: jump_vm_name
      adminUsername: jump_vm_admin_uname
      adminPassword: jump_vm_admin_pwd
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: jump_vm_image
      osDisk: {
        osType: 'Linux'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Empty'
          caching: 'None'
          diskSizeGB: jump_vm_disk_size
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpVMNic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

resource linuxVMExtensions 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: jumpVM
  name: 'customScript'
  location: resourceGroup().location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
    }
    protectedSettings: {
      commandToExecute: './${install_script_command} ${install_script_arg1}'
      fileUris: [
        install_script_location
      ]
    }
  }
}

resource bastionPIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: bastion_host_pip_name
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: bastion_host_dns_name
    }
    idleTimeoutInMinutes: 4
  }
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: hubVnet_name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnet_addr_cidr
      ]
    }
    subnets: [
      {
        name: hubVnet_bastion_subnet_name
        properties: {
          addressPrefix: hubVnet_bastion_subnet_cidr
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2020-11-01' = {
  name: bastion_host_name
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: 'bastion_ip_config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastionPIP.id
          }
          subnet: {
            id: hubVirtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
    dnsName: bastion_host_dns_name
  }
}

resource acrRegistry 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acr_name
  location: resourceGroup().location
  sku: {
    name: acr_sku
  }
  properties: {
    adminUserEnabled: false
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
    anonymousPullEnabled: false
  }
}

module aksModule './modules/aks_deploy.bicep' = {
  name: 'aksDeploy'
  params: {
    location: resourceGroup().location
    vnet_subnet_id: spokeVirtualNetwork.properties.subnets[0].id
    aks_cluster_name: aks_cluster_name
    aks_dns_prefix: aks_dns_prefix
    aks_node_count: aks_node_count
    aks_cni_plugin: aks_cni_plugin
    aks_service_cidr: aks_service_cidr
    aks_dns_service_ip: aks_dns_service_ip
    aks_pod_cidr: aks_pod_cidr
    aks_node_count_min: aks_node_count_min
    aks_node_count_max: aks_node_count_max
    aks_node_vm_size: aks_node_vm_size
    aks_node_osdisk_type: aks_node_osdisk_type
    aks_node_osdisk_size: aks_node_osdisk_size
    aks_nodepool_tags: aks_nodepool_tags
    aks_load_balancer_sku: aks_load_balancer_sku
    aks_max_pods: aks_max_pods
  }
}

resource spokeToHubVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${devVnet_name}/labToHubVnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVirtualNetwork.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        hubVnet_addr_cidr
      ]
    }
  }
}

resource hubToSpokeVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${hubVnet_name}/hubToLabVnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVirtualNetwork.id
    }
    remoteAddressSpace: {
      addressPrefixes: [
        devVnet_addr_cidr
      ]
    }
  }
}

output jumpBoxUname string = jump_vm_name
output jumpBoxPassword string = jump_vm_admin_pwd
output windowsNodeUname string = aks_windows_adm_uname
output windowsNodePassword string = aks_windows_adm_pwd
