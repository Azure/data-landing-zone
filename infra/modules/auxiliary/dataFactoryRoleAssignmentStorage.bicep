// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to a storage account file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param datafactoryId string

// Variables
var storageAccountFileSystemName = length(split(storageAccountFileSystemId, '/')) >= 13 ? last(split(storageAccountFileSystemId, '/')) : 'incorrectSegmentLength'
var storageAccountName = length(split(storageAccountFileSystemId, '/')) >= 13 ? split(storageAccountFileSystemId, '/')[8] : 'incorrectSegmentLength'
var datafactorySubscriptionId = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[2] : subscription().subscriptionId
var datafactoryResourceGroupName = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[4] : resourceGroup().name
var datafactoryName = length(split(datafactoryId, '/')) >= 9 ? last(split(datafactoryId, '/')) : 'incorrectSegmentLength'

// Resources
resource storageAccountFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' existing = {
  name: '${storageAccountName}/default/${storageAccountFileSystemName}'
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryName
  scope: resourceGroup(datafactorySubscriptionId, datafactoryResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(storageAccountFileSystem.id, datafactory.id))
  scope: storageAccountFileSystem
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: datafactory.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
