// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create integration resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param storageAccountRawFileSystemId string
param storageAccountEnrichedCuratedFileSystemId string
param vnetId string
param databricksIntegration001PrivateSubnetName string
param databricksIntegration001PublicSubnetName string
param subnetId string
param purviewId string = ''
param purviewManagedStorageId string = ''
param purviewManagedEventHubId string = ''
param storageRawId string
param storageEnrichedCuratedId string
param keyVault001Id string
param sqlServer001Id string
param sqlDatabase001Name string
param privateDnsZoneIdDataFactory string = ''
param privateDnsZoneIdDataFactoryPortal string = ''
param privateDnsZoneIdEventhubNamespace string = ''

// Variables
var databricksIntegration001Name = '${prefix}-integration-databricks001'
var eventhubNamespaceIntegration001Name = '${prefix}-integration-eventhub001'
var datafactoryIntegration001Name = '${prefix}-integration-datafactory001'
var storageAccountRawSubscriptionId = length(split(storageAccountRawFileSystemId, '/')) >= 13 ? split(storageAccountRawFileSystemId, '/')[2] : subscription().subscriptionId
var storageAccountRawResourceGroupName = length(split(storageAccountRawFileSystemId, '/')) >= 13 ? split(storageAccountRawFileSystemId, '/')[4] : resourceGroup().name
var storageAccountEnrichedCuratedSubscriptionId = length(split(storageAccountEnrichedCuratedFileSystemId, '/')) >= 13 ? split(storageAccountEnrichedCuratedFileSystemId, '/')[2] : subscription().subscriptionId
var storageAccountEnrichedCuratedResourceGroupName = length(split(storageAccountEnrichedCuratedFileSystemId, '/')) >= 13 ? split(storageAccountEnrichedCuratedFileSystemId, '/')[4] : resourceGroup().name

// Resources
module databricksIntegration001 'services/databricks.bicep' = {
  name: 'databricksIntegration001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    databricksName: databricksIntegration001Name
    vnetId: vnetId
    privateSubnetName: databricksIntegration001PrivateSubnetName
    publicSubnetName: databricksIntegration001PublicSubnetName
  }
}

module eventhubNamespaceIntegration001 'services/eventhubnamespace.bicep' = {
  name: 'eventhubNamespaceIntegration001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    eventhubnamespaceName: eventhubNamespaceIntegration001Name
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
    eventhubnamespaceMinThroughput: 1
    eventhubnamespaceMaxThroughput: 1
  }
}

module datafactoryIntegration001 'services/datafactorysharedintegration.bicep' = {
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
    purviewManagedStorageId: purviewManagedStorageId
    purviewManagedEventHubId: purviewManagedEventHubId
    storageRawId: storageRawId
    storageEnrichedCuratedId: storageEnrichedCuratedId
    databricks001Id: databricksIntegration001.outputs.databricksId
    databricks001WorkspaceUrl: databricksIntegration001.outputs.databricksWorkspaceUrl
    keyVault001Id: keyVault001Id
    sqlServer001Id: sqlServer001Id
    sqlDatabase001Name: sqlDatabase001Name
  }
}

module datafactory001StorageRawRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageRawRoleAssignment'
  scope: resourceGroup(storageAccountRawSubscriptionId, storageAccountRawResourceGroupName)
  params: {
    datafactoryId: datafactoryIntegration001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountRawFileSystemId
  }
}

module datafactory001StorageEnrichedCuratedRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageEnrichedCuratedRoleAssignment'
  scope: resourceGroup(storageAccountEnrichedCuratedSubscriptionId, storageAccountEnrichedCuratedResourceGroupName)
  params: {
    datafactoryId: datafactoryIntegration001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountEnrichedCuratedFileSystemId
  }
}

module datafactory001DatabricksRoleAssignment 'auxiliary/dataFactoryRoleAssignmentDatabricks.bicep' = {
  name: 'datafactory001DatabricksRoleAssignment'
  scope: resourceGroup()
  params: {
    datafactoryId: datafactoryIntegration001.outputs.datafactoryId
    databricksId: databricksIntegration001.outputs.databricksId
  }
}

// Outputs
output datafactoryIntegration001Id string = datafactoryIntegration001.outputs.datafactoryId
output databricksIntegration001Id string = databricksIntegration001.outputs.databricksId
output databricksIntegration001ApiUrl string = databricksIntegration001.outputs.databricksApiUrl
