targetScope = 'subscription'

// Parameters
@description('Specifies the location for all resources.')
param location string

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Specifies the environment of the deployment.')
param environment string

@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string

@description('Specifies the address space of the vnet.')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Specifies the address space of the subnet that is use for Azure Firewall.')
param servicesSubnetAddressPrefix string = '10.1.0.0/24'

@description('Specifies the private IP address of the central firewall.')
param firewallPrivateIp string = '10.0.0.4'

@description('Specifies the private IP addresses of the dns servers.')
param dnsServerAdresses array = [
  '10.0.0.4'
]

// Variables
var name = toLower('${prefix}-${environment}')
var tags = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}

// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tags
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: '${name}-network'
  scope: networkResourceGroup
  params: {
    prefix: name
    location: location
    tags: tags
    vnetAddressPrefix: vnetAddressPrefix
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    dnsServerAdresses: dnsServerAdresses
    enableDnsAndFirewallDeployment: true
    firewallPrivateIp: firewallPrivateIp
  }
}

