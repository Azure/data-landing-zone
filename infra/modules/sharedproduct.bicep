// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create shared product resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param administratorUsername string = 'SqlServerMainUser'
@secure()
param administratorPassword string
param synapseSqlAdminGroupName string = ''
param synapseSqlAdminGroupObjectID string = ''
param synapseProduct001DefaultStorageAccountFileSystemId string
param synapseProduct001ComputeSubnetId string = ''
param privateDnsZoneIdSynapseSql string = ''
param privateDnsZoneIdSynapseDev string = ''
param vnetId string
param databricksProduct001PrivateSubnetName string
param databricksProduct001PublicSubnetName string
param subnetId string
param purviewId string = ''

// Variables
var synapseProduct001DefaultStorageAccountSubscriptionId = length(split(synapseProduct001DefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseProduct001DefaultStorageAccountFileSystemId, '/')[2] : subscription().subscriptionId
var synapseProduct001DefaultStorageAccountResourceGroupName = length(split(synapseProduct001DefaultStorageAccountFileSystemId, '/')) >= 13 ? split(synapseProduct001DefaultStorageAccountFileSystemId, '/')[4] : resourceGroup().name
var databricksProduct001Name = '${prefix}-product-databricks001'
var synapseProduct001Name = '${prefix}-product-synapse001'

// Resources
module databricksProduct001 'services/databricks.bicep' = {
  name: 'databricksProduct001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    databricksName: databricksProduct001Name
    privateSubnetName: databricksProduct001PrivateSubnetName
    publicSubnetName: databricksProduct001PublicSubnetName
    vnetId: vnetId
  }
}

module synapseProduct001 'services/synapse.bicep' = {
  name: 'synapseProduct001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    synapseName: synapseProduct001Name
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    synapseSqlAdminGroupName: synapseSqlAdminGroupName
    synapseSqlAdminGroupObjectID: synapseSqlAdminGroupObjectID
    synapseDefaultStorageAccountFileSystemId: synapseProduct001DefaultStorageAccountFileSystemId
    synapseComputeSubnetId: synapseProduct001ComputeSubnetId
    privateDnsZoneIdSynapseDev: privateDnsZoneIdSynapseDev
    privateDnsZoneIdSynapseSql: privateDnsZoneIdSynapseSql
    purviewId: purviewId
  }
}

module synapse001StorageRoleAssignment 'auxiliary/synapseRoleAssignmentStorage.bicep' = {
  name: 'synapse001StorageRoleAssignment'
  scope: resourceGroup(synapseProduct001DefaultStorageAccountSubscriptionId, synapseProduct001DefaultStorageAccountResourceGroupName)
  params: {
    storageAccountFileSystemId: synapseProduct001DefaultStorageAccountFileSystemId
    synapseId: synapseProduct001.outputs.synapseId
  }
}

// Outputs
output databricksProduct001Id string = databricksProduct001.outputs.databricksId
output databricksProduct001ApiUrl string = databricksProduct001.outputs.databricksApiUrl
