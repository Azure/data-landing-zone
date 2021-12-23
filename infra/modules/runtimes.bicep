// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create runtime resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param administratorUsername string = 'VmssMainUser'
@secure()
param administratorPassword string
param privateDnsZoneIdDataFactory string = ''
param privateDnsZoneIdDataFactoryPortal string = ''
param purviewId string = ''
param purviewSelfHostedIntegrationRuntimeAuthKey string = ''
param deploySelfHostedIntegrationRuntimes bool = false
param datafactoryIds array

// Variables
var datafactoryRuntimes001Name = '${prefix}-runtime-datafactory001'
var shir001Name = '${prefix}-shir001'
var shir002Name = '${prefix}-shir002'

// Resources
module datafactoryRuntimes001 'services/datafactoryruntime.bicep' = {
  name: 'datafactoryRuntimes001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    datafactoryName: datafactoryRuntimes001Name
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    purviewId: purviewId
  }
}

resource datafactoryRuntimes001IntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${datafactoryRuntimes001Name}/dataLandingZoneShir-${shir001Name}'
  dependsOn: [
    datafactoryRuntimes001
  ]
  properties: {
    type: 'SelfHosted'
    description: 'Data Landing Zone - Self Hosted Integration Runtime running on ${shir001Name}'
  }
}

module datafactoryRuntimes001SelfHostedIntegrationRuntime001 'services/selfHostedIntegrationRuntime.bicep' = if (deploySelfHostedIntegrationRuntimes) {
  name: 'datafactoryRuntimes001SelfHostedIntegrationRuntime001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    datafactoryIntegrationRuntimeAuthKey: listAuthKeys(datafactoryRuntimes001IntegrationRuntime001.id, datafactoryRuntimes001IntegrationRuntime001.apiVersion).authKey1
    vmssName: shir001Name
    vmssSkuCapacity: 1
    vmssSkuName: 'Standard_DS2_v2'
    vmssSkuTier: 'Standard'
  }
}

module shareDatafactoryRuntimes001IntegrationRuntime001 'auxiliary/shareSelfHostedIntegrationRuntime.bicep' = [ for (datafactoryId, i) in datafactoryIds: if (deploySelfHostedIntegrationRuntimes) {
  name: 'shareDatafactoryRuntimes001IntegrationRuntime001-${i}'
  dependsOn: [
    datafactoryRuntimes001SelfHostedIntegrationRuntime001
  ]
  scope: resourceGroup(split(datafactoryId, '/')[2], split(datafactoryId, '/')[4])
  params: {
    datafactorySourceId: datafactoryRuntimes001.outputs.datafactoryId
    datafactorySourceShirId: datafactoryRuntimes001IntegrationRuntime001.id
    datafactoryDestinationId: datafactoryId
  }
}]

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
    vmssName: shir002Name
    vmssSkuCapacity: 1
    vmssSkuName: 'Standard_DS2_v2'
    vmssSkuTier: 'Standard'
  }
}

// Outputs
