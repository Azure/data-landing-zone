// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param storageAccountFileSystemId string
param synapseId string

// Variables
var storageAccountFileSystemName = split(storageAccountFileSystemId, '/')[-1]
var storageAccountName = split(storageAccountFileSystemId, '/')[7]
var synapseSubscriptionId = split(synapseId, '/')[2]
var synapseResourceGroupName = split(synapseId, '/')[4]
var synapseName = last(split(synapseId, '/'))

// Resources
resource storageAccountFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' existing = {
  name: '${storageAccountName}/default/${storageAccountFileSystemName}'
}

resource synapse 'Microsoft.Synapse/workspaces@2021-03-01' existing = {
  name: synapseName
  scope: resourceGroup(synapseSubscriptionId, synapseResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(storageAccountFileSystem.id, synapse.id))
  scope: storageAccountFileSystem
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: synapse.identity.principalId
  }
}

// Outputs
