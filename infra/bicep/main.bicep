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
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    firewallPrivateIp: firewallPrivateIp
    dnsServerAdresses: dnsServerAdresses
    vnetAddressPrefix: vnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    databricksDomainPublicSubnetAddressPrefix: databricksDomainPublicSubnetAddressPrefix
    databricksDomainPrivateSubnetAddressPrefix: databricksDomainPrivateSubnetAddressPrefix
    databricksProductPublicSubnetAddressPrefix: databricksProductPublicSubnetAddressPrefix
    databricksProductPrivateSubnetAddressPrefix: databricksProductPrivateSubnetAddressPrefix
    powerBiGatewaySubnetAddressPrefix: powerBiGatewaySubnetAddressPrefix
    dataDomain001SubnetAddressPrefix: dataDomain001SubnetAddressPrefix
    dataDomain002SubnetAddressPrefix: dataDomain002SubnetAddressPrefix
    dataProduct001SubnetAddressPrefix: dataProduct001SubnetAddressPrefix
    dataProduct002SubnetAddressPrefix: dataProduct002SubnetAddressPrefix
    dataManagementZoneVnetId: dataManagementZoneVnetId
  }
}

// Management resources
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-mgmt'
  location: location
  tags: tags
  properties: {}
}

// Logging resources
resource loggingResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-logging'
  location: location
  tags: tags
  properties: {}
}

module loggingServices 'modules/logging.bicep' = {
  name: 'loggingServices'
  scope: loggingResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}


