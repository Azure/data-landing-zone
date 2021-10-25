// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

targetScope = 'subscription'

// General parameters
@description('Specifies the location for all resources.')
param location string
@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Specifies the environment of the deployment.')
param environment string = 'dev'
@minLength(2)
@maxLength(10)
@description('Specifies the prefix for all resources created in this deployment.')
param prefix string
@description('Specifies the tags that you want to apply to all resources.')
param tags object = {}

// Network parameters
@description('Specifies the address space of the vnet of the data landing zone.')
param vnetAddressPrefix string = '10.1.0.0/16'
@description('Specifies the address space of the subnet that is used for general services of the data landing zone.')
param servicesSubnetAddressPrefix string = '10.1.0.0/24'
@description('Specifies the address space of the public subnet that is used for the shared integration databricks workspace.')
param databricksIntegrationPublicSubnetAddressPrefix string = '10.1.1.0/24'
@description('Specifies the address space of the private subnet that is used for the shared integration databricks workspace.')
param databricksIntegrationPrivateSubnetAddressPrefix string = '10.1.2.0/24'
@description('Specifies the address space of the public subnet that is used for the shared product databricks workspace.')
param databricksProductPublicSubnetAddressPrefix string = '10.1.3.0/24'
@description('Specifies the address space of the private subnet that is used for the shared product databricks workspace.')
param databricksProductPrivateSubnetAddressPrefix string = '10.1.4.0/24'
@description('Specifies the address space of the subnet that is used for the power bi gateway.')
param powerBiGatewaySubnetAddressPrefix string = '10.1.5.0/24'
@description('Specifies the address space of the subnet that is used for data integration 001.')
param dataIntegration001SubnetAddressPrefix string = '10.1.6.0/24'
@description('Specifies the address space of the subnet that is used for data integration 002.')
param dataIntegration002SubnetAddressPrefix string = '10.1.7.0/24'
@description('Specifies the address space of the subnet that is used for data product 001.')
param dataProduct001SubnetAddressPrefix string = '10.1.8.0/24'
@description('Specifies the address space of the subnet that is used for data product 002.')
param dataProduct002SubnetAddressPrefix string = '10.1.9.0/24'
@description('Specifies the resource Id of the vnet in the data management zone.')
param dataManagementZoneVnetId string = ''
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
param purviewId string = ''
@description('Specifies the resource ID of the managed storage of the central purview instance.')
param purviewManagedStorageId string = ''
@description('Specifies the resource ID of the managed event hub of the central purview instance.')
param purviewManagedEventHubId string = ''
@secure()
@description('Specifies the Auth Key for the Self-hosted integration runtime of Purview.')
param purviewSelfHostedIntegrationRuntimeAuthKey string = ''
@description('Specifies whether the self-hosted integration runtimes should be deployed. This only works, if the pwsh script was uploded and is available.')
param deploySelfHostedIntegrationRuntimes bool = false
@description('Specifies whether the deployment was submitted through the Azure Portal.')
param portalDeployment bool = false

// Private DNS Zone parameters
@description('Specifies the resource ID of the private DNS zone for Key Vault.')
param privateDnsZoneIdKeyVault string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory.')
param privateDnsZoneIdDataFactory string = ''
@description('Specifies the resource ID of the private DNS zone for Data Factory Portal.')
param privateDnsZoneIdDataFactoryPortal string = ''
@description('Specifies the resource ID of the private DNS zone for Blob Storage.')
param privateDnsZoneIdBlob string = ''
@description('Specifies the resource ID of the private DNS zone for Datalake Storage.')
param privateDnsZoneIdDfs string = ''
@description('Specifies the resource ID of the private DNS zone for Sql Server.')
param privateDnsZoneIdSqlServer string = ''
@description('Specifies the resource ID of the private DNS zone for My SQL Server.')
param privateDnsZoneIdMySqlServer string = ''
@description('Specifies the resource ID of the private DNS zone for EventHub Namespaces.')
param privateDnsZoneIdEventhubNamespace string = ''
@description('Specifies the resource ID of the private DNS zone for Synapse Dev.')
param privateDnsZoneIdSynapseDev string = ''
@description('Specifies the resource ID of the private DNS zone for Synapse Sql.')
param privateDnsZoneIdSynapseSql string = ''

// Variables
var name = toLower('${prefix}-${environment}')
var tagsDefault = {
  Owner: 'Enterprise Scale Analytics'
  Project: 'Enterprise Scale Analytics'
  Environment: environment
  Toolkit: 'bicep'
  Name: name
}
var tagsJoined = union(tagsDefault, tags)
var administratorUsername = 'SuperMainUser'

// Network resources
resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-network'
  location: location
  tags: tagsJoined
  properties: {}
}

module networkServices 'modules/network.bicep' = {
  name: 'networkServices'
  scope: networkResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    firewallPrivateIp: firewallPrivateIp
    dnsServerAdresses: dnsServerAdresses
    vnetAddressPrefix: vnetAddressPrefix
    servicesSubnetAddressPrefix: servicesSubnetAddressPrefix
    databricksIntegrationPublicSubnetAddressPrefix: databricksIntegrationPublicSubnetAddressPrefix
    databricksIntegrationPrivateSubnetAddressPrefix: databricksIntegrationPrivateSubnetAddressPrefix
    databricksProductPublicSubnetAddressPrefix: databricksProductPublicSubnetAddressPrefix
    databricksProductPrivateSubnetAddressPrefix: databricksProductPrivateSubnetAddressPrefix
    powerBiGatewaySubnetAddressPrefix: powerBiGatewaySubnetAddressPrefix
    dataIntegration001SubnetAddressPrefix: dataIntegration001SubnetAddressPrefix
    dataIntegration002SubnetAddressPrefix: dataIntegration002SubnetAddressPrefix
    dataProduct001SubnetAddressPrefix: dataProduct001SubnetAddressPrefix
    dataProduct002SubnetAddressPrefix: dataProduct002SubnetAddressPrefix
    dataManagementZoneVnetId: dataManagementZoneVnetId
  }
}

// Management resources
resource managementResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-mgmt'
  location: location
  tags: tagsJoined
  properties: {}
}

// Logging resources
resource loggingResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-logging'
  location: location
  tags: tagsJoined
  properties: {}
}

module loggingServices 'modules/logging.bicep' = {
  name: 'loggingServices'
  scope: loggingResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

// Runtime resources
resource runtimesResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-runtimes'
  location: location
  tags: tagsJoined
  properties: {}
}

module runtimeServices 'modules/runtimes.bicep' = {
  name: 'runtimeServices'
  scope: runtimesResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    purviewId: purviewId
    purviewSelfHostedIntegrationRuntimeAuthKey: purviewSelfHostedIntegrationRuntimeAuthKey
    deploySelfHostedIntegrationRuntimes: deploySelfHostedIntegrationRuntimes
    datafactoryIds: [
      sharedIntegrationServices.outputs.datafactoryIntegration001Id
    ]
    portalDeployment: portalDeployment
  }
}

// Storage resources
resource storageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-storage'
  location: location
  tags: tagsJoined
  properties: {}
}

module storageServices 'modules/storage.bicep' = {
  name: 'storageServices'
  scope: storageResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
  }
}

// External storage resources
resource externalStorageResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-externalstorage'
  location: location
  tags: tagsJoined
  properties: {}
}

module externalStorageServices 'modules/externalstorage.bicep' = {
  name: 'externalStorageServices'
  scope: externalStorageResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
  }
}

// Metadata resources
resource metadataResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-metadata'
  location: location
  tags: tagsJoined
  properties: {}
}

module metadataServices 'modules/metadata.bicep' = {
  name: 'metadataServices'
  scope: metadataResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
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

// Shared integration services
resource sharedIntegrationResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-integration'
  location: location
  tags: tagsJoined
  properties: {}
}

module sharedIntegrationServices 'modules/sharedintegration.bicep' = {
  name: 'sharedIntegrationServices'
  scope: sharedIntegrationResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
    subnetId: networkServices.outputs.servicesSubnetId
    vnetId: networkServices.outputs.vnetId
    databricksIntegration001PrivateSubnetName: networkServices.outputs.databricksIntegrationPrivateSubnetName
    databricksIntegration001PublicSubnetName: networkServices.outputs.databricksIntegrationPublicSubnetName
    storageRawId: storageServices.outputs.storageRawId
    storageAccountRawFileSystemId: storageServices.outputs.storageRawFileSystemId
    storageEnrichedCuratedId: storageServices.outputs.storageEnrichedCuratedId
    storageAccountEnrichedCuratedFileSystemId: storageServices.outputs.storageEnrichedCuratedFileSystemId
    keyVault001Id: metadataServices.outputs.keyVault001Id
    sqlServer001Id: metadataServices.outputs.sqlServer001Id
    sqlDatabase001Name: metadataServices.outputs.sqlServer001DatabaseName
    purviewId: purviewId
    purviewManagedStorageId: purviewManagedStorageId
    purviewManagedEventHubId: purviewManagedEventHubId
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
  }
}

// Shared product resources
resource sharedProductResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-shared-product'
  location: location
  tags: tagsJoined
  properties: {}
}

module sharedProductServices 'modules/sharedproduct.bicep' = {
  name: 'sharedProductServices'
  scope: sharedProductResourceGroup
  params: {
    location: location
    prefix: name
    tags: tagsJoined
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

// Data integration resources 001
resource dataIntegration001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-di001'
  location: location
  tags: tagsJoined
  properties: {}
}

resource dataIntegration002ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-di002'
  location: location
  tags: tagsJoined
  properties: {}
}

// Data product resources 001
resource dataProduct001ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dp001'
  location: location
  tags: tagsJoined
  properties: {}
}

resource dataProduct002ResourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: '${name}-dp002'
  location: location
  tags: tagsJoined
  properties: {}
}

// Outputs
output vnetId string = networkServices.outputs.vnetId
output nsgId string = networkServices.outputs.nsgId
output routeTableId string = networkServices.outputs.routeTableId
output artifactstorage001ResourceGroupName string = split(runtimeServices.outputs.artifactstorage001Id, '/')[4]
output artifactstorage001Name string = last(split(runtimeServices.outputs.artifactstorage001Id, '/'))
output artifactstorage001ContainerName string = runtimeServices.outputs.artifactstorage001ContainerName
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
output databricksIntegration001ApiUrl string = sharedIntegrationServices.outputs.databricksIntegration001ApiUrl
output databricksIntegration001Id string = sharedIntegrationServices.outputs.databricksIntegration001Id
output databricksIntegration001SubscriptionId string = split(sharedIntegrationServices.outputs.databricksIntegration001Id, '/')[2]
output databricksIntegration001ResourceGroupName string = split(sharedIntegrationServices.outputs.databricksIntegration001Id, '/')[4]
output databricksIntegration001Name string = last(split(sharedIntegrationServices.outputs.databricksIntegration001Id, '/'))
output databricksProduct001ApiUrl string = sharedProductServices.outputs.databricksProduct001ApiUrl
output databricksProduct001Id string = sharedProductServices.outputs.databricksProduct001Id
output databricksProduct001SubscriptionId string = split(sharedProductServices.outputs.databricksProduct001Id, '/')[2]
output databricksProduct001ResourceGroupName string = split(sharedProductServices.outputs.databricksProduct001Id, '/')[4]
output databricksProduct001Name string = last(split(sharedProductServices.outputs.databricksProduct001Id, '/'))
