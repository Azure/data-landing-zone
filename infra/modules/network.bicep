// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param firewallPrivateIp string = '10.0.0.4'
param dnsServerAdresses array = [
  '10.0.0.4'
]
param vnetAddressPrefix string = '10.1.0.0/16'
param servicesSubnetAddressPrefix string = '10.1.0.0/24'
param databricksIntegrationPublicSubnetAddressPrefix string = '10.1.1.0/24'
param databricksIntegrationPrivateSubnetAddressPrefix string = '10.1.2.0/24'
param databricksProductPublicSubnetAddressPrefix string = '10.1.3.0/24'
param databricksProductPrivateSubnetAddressPrefix string = '10.1.4.0/24'
param powerBiGatewaySubnetAddressPrefix string = '10.1.5.0/24'
param dataIntegration001SubnetAddressPrefix string = '10.1.6.0/24'
param dataIntegration002SubnetAddressPrefix string = '10.1.7.0/24'
param dataProduct001SubnetAddressPrefix string = '10.1.8.0/24'
param dataProduct002SubnetAddressPrefix string = '10.1.9.0/24'
param dataManagementZoneVnetId string = ''

// Variables
var servicesSubnetName = 'ServicesSubnet'
var databricksIntegrationPrivateSubnetName = 'DatabricksIntegrationSubnetPrivate'
var databricksIntegrationPublicSubnetName = 'DatabricksIntegrationSubnetPublic'
var databricksProductPrivateSubnetName = 'DatabricksProductSubnetPrivate'
var databricksProductPublicSubnetName = 'DatabricksProductSubnetPublic'
var powerBiGatewaySubnetName = 'PowerBIGatewaySubnet'
var dataIntegration001SubnetName = 'DataIntegration001Subnet'
var dataIntegration002SubnetName = 'DataIntegration002Subnet'
var dataProduct001SubnetName = 'DataProduct001Subnet'
var dataProduct002SubnetName = 'DataProduct002Subnet'
var dataManagementZoneVnetSubscriptionId = length(split(dataManagementZoneVnetId, '/')) >= 9 ? split(dataManagementZoneVnetId, '/')[2] : subscription().subscriptionId
var dataManagementZoneVnetResourceGroupName = length(split(dataManagementZoneVnetId, '/')) >= 9 ? split(dataManagementZoneVnetId, '/')[4] : resourceGroup().name
var dataManagementZoneVnetName = length(split(dataManagementZoneVnetId, '/')) >= 9 ? last(split(dataManagementZoneVnetId, '/')) : 'incorrectSegmentLength'

// Resources
resource routeTable 'Microsoft.Network/routeTables@2020-11-01' = {
  name: '${prefix}-routetable'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'to-firewall-default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${prefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource databricksNsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: '${prefix}-databricks-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
        properties: {
          description: 'Required for worker nodes communication within a cluster.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 101
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
        properties: {
          description: 'Required for workers communication with Azure SQL services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3306'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
        properties: {
          description: 'Required for workers communication with Azure Storage services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 103
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
        properties: {
          description: 'Required for worker communication with Azure Eventhub services.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '9093'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 104
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp'
        properties: {
          description: 'Required for workers communication with Databricks Webapp.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureDatabricks'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: '${prefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: dnsServerAdresses
    }
    enableDdosProtection: false
    subnets: [
      {
        name: servicesSubnetName
        properties: {
          addressPrefix: servicesSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: databricksIntegrationPublicSubnetName
        properties: {
          addressPrefix: databricksIntegrationPublicSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'DatabricksSubnetDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: databricksIntegrationPrivateSubnetName
        properties: {
          addressPrefix: databricksIntegrationPrivateSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'DatabricksSubnetDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: databricksProductPublicSubnetName
        properties: {
          addressPrefix: databricksProductPublicSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'DatabricksSubnetDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: databricksProductPrivateSubnetName
        properties: {
          addressPrefix: databricksProductPrivateSubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: databricksNsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'DatabricksSubnetDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: powerBiGatewaySubnetName
        properties: {
          addressPrefix: powerBiGatewaySubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: [
            {
              name: 'PowerBIGatewaySubnetDelegation'
              properties: {
                serviceName: 'Microsoft.PowerPlatform/vnetaccesslinks'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: dataIntegration001SubnetName
        properties: {
          addressPrefix: dataIntegration001SubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: dataIntegration002SubnetName
        properties: {
          addressPrefix: dataIntegration002SubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: dataProduct001SubnetName
        properties: {
          addressPrefix: dataProduct001SubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
      {
        name: dataProduct002SubnetName
        properties: {
          addressPrefix: dataProduct002SubnetAddressPrefix
          addressPrefixes: []
          networkSecurityGroup: {
            id: nsg.id
          }
          routeTable: {
            id: routeTable.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          serviceEndpointPolicies: []
          serviceEndpoints: []
        }
      }
    ]
  }
}

resource dataLandingZoneDataManagementZoneVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = if (!empty(dataManagementZoneVnetId)) {
  name: dataManagementZoneVnetName
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: dataManagementZoneVnetId
    }
    useRemoteGateways: false
  }
}

module dataManagementZoneDataLandingZoneVnetPeering 'auxiliary/dataManagementZoneVnetPeering.bicep' = if (!empty(dataManagementZoneVnetId)) {
  name: 'dataManagementZoneDataLandingZoneVnetPeering-${prefix}'
  scope: resourceGroup(dataManagementZoneVnetSubscriptionId, dataManagementZoneVnetResourceGroupName)
  params: {
    dataLandingZoneVnetId: vnet.id
    dataManagementZoneVnetId: dataManagementZoneVnetId
  }
}

// Outputs
output vnetId string = vnet.id
output nsgId string = nsg.id
output routeTableId string = routeTable.id
output servicesSubnetId string = vnet.properties.subnets[0].id
output databricksIntegrationPublicSubnetName string = databricksIntegrationPublicSubnetName
output databricksIntegrationPrivateSubnetName string = databricksIntegrationPrivateSubnetName
output databricksProductPublicSubnetName string = databricksProductPublicSubnetName
output databricksProductPrivateSubnetName string = databricksProductPrivateSubnetName
