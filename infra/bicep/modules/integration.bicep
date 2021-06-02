// This template is used as a module from the main.bicep template. 
// The module contains a template to create integration resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param administratorUsername string = 'VmssMainUser'
@secure()
param administratorPassword string
param privateDnsZoneIdDataFactory string
param privateDnsZoneIdDataFactoryPortal string
param purviewId string
param purviewSelfHostedIntegrationRuntimeAuthKey string = ''
param deploySelfHostedIntegrationRuntimes bool

// Variables
var artifactstorage001Name = '${prefix}-artifact001'
var datafactoryIntegration001Name = '${prefix}-integration-datafactory001'
var shir001Name = '${prefix}-shir001'

// Resources
module artifactstorage001 'services/artifactstorage.bicep' = {
  name: 'artifactstorage001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    artifactstorageName: artifactstorage001Name
  }
}

module datafactoryIntegration001 'services/datafactoryintegration.bicep' = {
  name: 'datafactoryIntegration001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    datafactoryName: datafactoryIntegration001Name
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    purviewId: purviewId
  }
}

resource datafactoryIntegration001IntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = if (deploySelfHostedIntegrationRuntimes) {
  name: '${datafactoryIntegration001Name}/dataLandingZoneSelfHostedIntegrationRuntime${shir001Name}'
  dependsOn: [
    datafactoryIntegration001
  ]
  properties: {
    type: 'SelfHosted'
    description: 'Data Landing Zone - Self Hosted Integration Runtime running on ${shir001Name}'
  }
}

module datafactory001SelfHostedIntegrationRuntime001 'services/selfHostedIntegrationRuntime.bicep' = if (deploySelfHostedIntegrationRuntimes) {
  name: 'datafactory001SelfHostedIntegrationRuntime001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    datafactoryIntegrationRuntimeAuthKey: listAuthKeys(datafactoryIntegration001IntegrationRuntime001.id, datafactoryIntegration001IntegrationRuntime001.apiVersion).authKey1
    storageAccountContainerName: artifactstorage001.outputs.storageAccountContainerName
    storageAccountId: artifactstorage001.outputs.storageAccountId
    vmssName: shir001Name
    vmssSkuCapacity: 1
    vmssSkuName: 'Standard_DS2_v2'
    vmssSkuTier: 'Standard'
  }
}

module purviewSelfHostedIntegrationRuntime001 'services/selfHostedIntegrationRuntime.bicep' = if (deploySelfHostedIntegrationRuntimes && purviewSelfHostedIntegrationRuntimeAuthKey != '') {
  name: 'purviewSelfHostedIntegrationRuntime001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    datafactoryIntegrationRuntimeAuthKey: purviewSelfHostedIntegrationRuntimeAuthKey
    storageAccountContainerName: artifactstorage001.outputs.storageAccountContainerName
    storageAccountId: artifactstorage001.outputs.storageAccountId
    vmssName: shir001Name
    vmssSkuCapacity: 1
    vmssSkuName: 'Standard_DS2_v2'
    vmssSkuTier: 'Standard'
  }
}

// Outputs
output artifactstorage001Id string = artifactstorage001.outputs.storageAccountId
output artifactstorage001ContainerName string = artifactstorage001.outputs.storageAccountContainerName
