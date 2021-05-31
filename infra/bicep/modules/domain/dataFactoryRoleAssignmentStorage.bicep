// This template is used as a module from the network.bicep template. 
// The module contains a template to create a role assignment to a storage account file system.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param datafactoryId string

// Variables
var storageAccountFileSystemName = last(split(storageAccountFileSystemId, '/'))
var storageAccountName = split(storageAccountFileSystemId, '/')[7]
var datafactorySubscriptionId = split(datafactoryId, '/')[2]
var datafactoryResourceGroupName = split(datafactoryId, '/')[4]
var datafactoryName = last(split(datafactoryId, '/'))

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
  }
}

// Outputs
