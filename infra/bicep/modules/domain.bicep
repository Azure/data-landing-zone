// This template is used as a module from the main.bicep template. 
// The module contains a template to create domain resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param storageAccountRawFileSystemId string
param storageAccountEnrichedCuratedFileSystemId string
param vnetId string
param databricksDomain001PrivateSubnetName string
param databricksDomain001PublicSubnetName string
param subnetId string
param purviewId string
param storageRawId string
param storageEnrichedCuratedId string
param keyVault001Id string
param sqlServer001Id string
param sqlDatabase001Name string
param privateDnsZoneIdDataFactory string
param privateDnsZoneIdDataFactoryPortal string
param privateDnsZoneIdEventhubNamespace string

// Variables
var databricksDomain001Name = '${prefix}-domain-databricks001'
var eventhubNamespaceDomain001Name = '${prefix}-domain-eventhub001'
var datafactoryDomain001Name = '${prefix}-domain-datafactory001'
var storageAccountRawSubscriptionId = split(storageAccountRawFileSystemId, '/')[2]
var storageAccountRawResourceGroupName = split(storageAccountRawFileSystemId, '/')[4]
var storageAccountEnrichedCuratedSubscriptionId = split(storageAccountEnrichedCuratedFileSystemId, '/')[2]
var storageAccountEnrichedCuratedResourceGroupName = split(storageAccountEnrichedCuratedFileSystemId, '/')[4]

// Resources
module databricksDomain001 'services/databricks.bicep' = {
  name: 'databricksDomain001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    databricksName: databricksDomain001Name
    vnetId: vnetId
    privateSubnetName: databricksDomain001PrivateSubnetName
    publicSubnetName: databricksDomain001PublicSubnetName
  }
}

module eventhubNamespaceDomain001 'services/eventhubnamespace.bicep' = {
  name: 'eventhubNamespaceDomain001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    eventhubnamespaceName: eventhubNamespaceDomain001Name
    privateDnsZoneIdEventhubNamespace: privateDnsZoneIdEventhubNamespace
  }
}

module datafactoryDomain001 'services/datafactorydomain.bicep' = {
  name: 'datafactoryDomain001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    datafactoryName: datafactoryDomain001Name
    privateDnsZoneIdDataFactory: privateDnsZoneIdDataFactory
    privateDnsZoneIdDataFactoryPortal: privateDnsZoneIdDataFactoryPortal
    purviewId: purviewId
    storageRawId: storageRawId
    storageEnrichedCuratedId: storageEnrichedCuratedId
    databricks001Id: databricksDomain001.outputs.databricksId
    databricks001WorkspaceUrl: databricksDomain001.outputs.databricksWorkspaceUrl
    keyVault001Id: keyVault001Id
    sqlServer001Id: sqlServer001Id
    sqlDatabase001Name: sqlDatabase001Name
  }
}

module datafactory001StorageRawRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageRawRoleAssignment'
  scope: resourceGroup(storageAccountRawSubscriptionId, storageAccountRawResourceGroupName)
  params: {
    datafactoryId: datafactoryDomain001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountRawFileSystemId
  }
}

module datafactory001StorageEnrichedCuratedRoleAssignment 'auxiliary/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactory001StorageEnrichedCuratedRoleAssignment'
  scope: resourceGroup(storageAccountEnrichedCuratedSubscriptionId, storageAccountEnrichedCuratedResourceGroupName)
  params: {
    datafactoryId: datafactoryDomain001.outputs.datafactoryId
    storageAccountFileSystemId: storageAccountEnrichedCuratedFileSystemId
  }
}

module datafactory001DatabricksRoleAssignment 'auxiliary/dataFactoryRoleAssignmentDatabricks.bicep' = {
  name: 'datafactory001DatabricksRoleAssignment'
  scope: resourceGroup()
  params: {
    datafactoryId: datafactoryDomain001.outputs.datafactoryId
    databricksId: databricksDomain001.outputs.databricksId
  }
}

// Outputs
