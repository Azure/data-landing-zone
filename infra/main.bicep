targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string = 'northeurope'
@allowed([
  'dev'
  'test'
  'prod'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(5)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string

// Network parameters
@description('Specifies the address space of the vnet of the data landing zone.')
param vnetAddressPrefix string = '10.1.0.0/16'
@description('Specifies the address space of the subnet that is used for general services of the data landing zone.')
param servicesSubnetAddressPrefix string = '10.1.0.0/24'
@description('Specifies the address space of the public subnet that is used for the shared domain databricks workspace.')
param databricksDomainPublicSubnetAddressPrefix string = '10.1.1.0/24'
@description('Specifies the address space of the private subnet that is used for the shared domain databricks workspace.')
param databricksDomainPrivateSubnetAddressPrefix string = '10.1.2.0/24'
@description('Specifies the address space of the public subnet that is used for the shared product databricks workspace.')
param databricksProductPublicSubnetAddressPrefix string = '10.1.3.0/24'
@description('Specifies the address space of the private subnet that is used for the shared product databricks workspace.')
param databricksProductPrivateSubnetAddressPrefix string = '10.1.4.0/24'
@description('Specifies the address space of the subnet that is used for the power bi gateway.')
param powerBiGatewaySubnetAddressPrefix string = '10.1.5.0/24'
@description('Specifies the address space of the subnet that is used for data domain 001.')
param dataDomain001SubnetAddressPrefix string = '10.1.6.0/24'
@description('Specifies the address space of the subnet that is used for data domain 002.')
param dataDomain002SubnetAddressPrefix string = '10.1.7.0/24'
@description('Specifies the address space of the subnet that is used for data product 001.')
param dataProduct001SubnetAddressPrefix string = '10.1.8.0/24'
@description('Specifies the address space of the subnet that is used for data product 002.')
param dataProduct002SubnetAddressPrefix string = '10.1.9.0/24'
@description('Specifies the resource Id of the vnet in the data management zone.')
param dataManagementZoneVnetId string
@description('Specifies the private IP address of the central firewall.')
param firewallPrivateIp string = '10.0.0.4'
@description('Specifies the private IP addresses of the dns servers.')
param dnsServerAdresses array = [
  '10.0.0.4'
]

// Resource parameters
@secure()
@description('Specifies the administrator password of the sql servers.')
param administratorPassword string
@description('Specifies the resource ID of the central purview instance.')
param purviewId string
@secure()
@description('Specifies the Auth Key for the Self-hosted integration runtime of Purview.')
param purviewSelfHostedIntegrationRuntimeAuthKey string = ''
@description('Specifies whether the self-hosted integration runtimes should be installed. This only works, if the pwsh script was uploded and is available.')
param deploySelfHostedIntegrationRuntimes bool = false

// Private DNS Zone parameters
@description('Specifies the resource ID of the private DNS zone for Key Vault.')
param privateDnsZoneIdKeyVault string
@description('Specifies the resource ID of the private DNS zone for Data Factory.')
param privateDnsZoneIdDataFactory string
@description('Specifies the resource ID of the private DNS zone for Data Factory Portal.')
param privateDnsZoneIdDataFactoryPortal string
@description('Specifies the resource ID of the private DNS zone for Blob Storage.')
param privateDnsZoneIdBlob string
@description('Specifies the resource ID of the private DNS zone for Datalake Storage.')
param privateDnsZoneIdDfs string
@description('Specifies the resource ID of the private DNS zone for Sql Server.')
param privateDnsZoneIdSqlServer string
@description('Specifies the resource ID of the private DNS zone for My SQL Server.')
param privateDnsZoneIdMySqlServer string
@description('Specifies the resource ID of the private DNS zone for EventHub Namespaces.')
param privateDnsZoneIdEventhubNamespace string
@description('Specifies the resource ID of the private DNS zone for Synapse Dev.')
param privateDnsZoneIdSynapseDev string
@description('Specifies the resource ID of the private DNS zone for Synapse Sql.')
param privateDnsZoneIdSynapseSql string

// Variables
var name = toLower('${prefix}-${environment}')
var tags = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var administratorUsername = 'SuperMainUser'

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

// Integration resources
resource integrationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-integration'
  location: location
  tags: tags
  properties: {}
}

module integrationServices 'modules/integration.bicep' = {
  name: 'integrationServices'
  scope: integrationResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    purviewId: purviewId
    purviewSelfHostedIntegrationRuntimeAuthKey: purviewSelfHostedIntegrationRuntimeAuthKey
    deploySelfHostedIntegrationRuntimes: deploySelfHostedIntegrationRuntimes
    datafactoryIds: [
      sharedDomainServices.outputs.datafactoryDomain001Id
    ]
  }
}

// Storage resources
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-storage'
  location: location
  tags: tags
  properties: {}
}

module storageServices 'modules/storage.bicep' = {
  name: 'storageServices'
  scope: storageResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
  }
}

// External storage resources
resource externalStorageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-externalstorage'
  location: location
  tags: tags
  properties: {}
}

module externalStorageServices 'modules/externalstorage.bicep' = {
  name: 'externalStorageServices'
  scope: externalStorageResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
  }
}

// Metadata resources
resource metadataResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-metadata'
  location: location
  tags: tags
  properties: {}
}

module metadataServices 'modules/metadata.bicep' = {
  name: 'metadataServices'
  scope: metadataResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    sqlserverAdminGroupName: ''
    sqlserverAdminGroupObjectID: ''
    mysqlserverAdminGroupName: ''
    mysqlserverAdminGroupObjectID: ''
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
    privateDnsZoneIdSqlServer: privateDnsZoneIdSqlServer
    privateDnsZoneIdMySqlServer: privateDnsZoneIdMySqlServer
  }
}

// Shared domain services
resource sharedDomainResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-domain'
  location: location
  tags: tags
  properties: {}
}

module sharedDomainServices 'modules/domain.bicep' = {
  name: 'sharedDomainServices'
  scope: sharedDomainResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    vnetId: networkServices.outputs.vnetId
    databricksDomain001PrivateSubnetName: networkServices.outputs.databricksDomainPrivateSubnetName
    databricksDomain001PublicSubnetName: networkServices.outputs.databricksDomainPublicSubnetName
    storageRawId: storageServices.outputs.storageRawId
    storageAccountRawFileSystemId: storageServices.outputs.storageRawFileSystemId
    storageEnrichedCuratedId: storageServices.outputs.storageEnrichedCuratedId
    storageAccountEnrichedCuratedFileSystemId: storageServices.outputs.storageEnrichedCuratedFileSystemId
    keyVault001Id: metadataServices.outputs.keyVault001Id
    sqlServer001Id: metadataServices.outputs.sqlServer001Id
    sqlDatabase001Name: metadataServices.outputs.sqlServer001DatabaseName
    purviewId: purviewId
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
  }
}

// Shared product resources
resource sharedProductResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-product'
  location: location
  tags: tags
  properties: {}
}

module sharedProductServices 'modules/product.bicep' = {
  name: 'sharedProductServices'
  scope: sharedProductResourceGroup
  params: {
    location: location
    prefix: name
    tags: tags
    subnetId: networkServices.outputs.servicesSubnetId
    vnetId: networkServices.outputs.vnetId
    databricksProduct001PrivateSubnetName: networkServices.outputs.databricksProductPrivateSubnetName
    databricksProduct001PublicSubnetName: networkServices.outputs.databricksProductPublicSubnetName
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    synapseProduct001DefaultStorageAccountFileSystemId: storageServices.outputs.storageWorkspaceFileSystemId
    synapseSqlAdminGroupName: ''
    synapseSqlAdminGroupObjectID: ''
    synapseProduct001ComputeSubnetId: ''
    purviewId: purviewId
    privateDnsZoneIdSynapseDev: privateDnsZoneIdSynapseDev
    privateDnsZoneIdSynapseSql: privateDnsZoneIdSynapseSql
  }
}

// Data domain resources 001
resource dataDomain001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dd001'
  location: location
  tags: tags
  properties: {}
}

// Data product resources 001
resource dataProduct001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dp001'
  location: location
  tags: tags
  properties: {}
}

// Outputs
output artifactstorage001ResourceGroupName string = split(integrationServices.outputs.artifactstorage001Id, '/')[4]
output artifactstorage001Name string = last(split(integrationServices.outputs.artifactstorage001Id, '/'))
output artifactstorage001ContainerName string = integrationServices.outputs.artifactstorage001ContainerName
output mySqlServer001SubscriptionId string = split(metadataServices.outputs.mySqlServer001Id, '/')[2]
output mySqlServer001ResourceGroupName string = split(metadataServices.outputs.mySqlServer001Id, '/')[4]
output mySqlServer001Name string = last(split(metadataServices.outputs.mySqlServer001Id, '/'))
output mySqlServer001KeyVaultid string = metadataServices.outputs.keyVault001Id
output mySqlServer001UsernameSecretName string = metadataServices.outputs.mySqlServer001UsernameSecretName
output mySqlServer001PasswordSecretName string = metadataServices.outputs.mySqlServer001PasswordSecretName
output mySqlServer001ConnectionStringSecretName string = metadataServices.outputs.mySqlServer001ConnectionStringSecretName
output logAnalyticsWorkspaceKeyVaultId string = loggingServices.outputs.logAnalytics001WorkspaceKeyVaultId
output logAnalyticsWorkspaceIdSecretName string = loggingServices.outputs.logAnalytics001WorkspaceIdSecretName
output logAnalyticsWorkspaceKeySecretName string = loggingServices.outputs.logAnalytics001WorkspaceKeySecretName
output databricksDomain001ApiUrl string = sharedDomainServices.outputs.databricksDomain001ApiUrl
output databricksDomain001Id string = sharedDomainServices.outputs.databricksDomain001Id
output databricksDomain001SubscriptionId string = split(sharedDomainServices.outputs.databricksDomain001Id, '/')[2]
output databricksDomain001ResourceGroupName string = split(sharedDomainServices.outputs.databricksDomain001Id, '/')[4]
output databricksDomain001Name string = last(split(sharedDomainServices.outputs.databricksDomain001Id, '/'))
output databricksProduct001ApiUrl string = sharedProductServices.outputs.databricksProduct001ApiUrl
output databricksProduct001Id string = sharedProductServices.outputs.databricksProduct001Id
output databricksProduct001SubscriptionId string = split(sharedProductServices.outputs.databricksProduct001Id, '/')[2]
output databricksProduct001ResourceGroupName string = split(sharedProductServices.outputs.databricksProduct001Id, '/')[4]
output databricksProduct001Name string = last(split(sharedProductServices.outputs.databricksProduct001Id, '/'))
