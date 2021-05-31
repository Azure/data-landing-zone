// This template is used as a module from the network.bicep template. 
// The module contains a template to create a role assignment to Databricks.
targetScope = 'resourceGroup'

// Parameters
param databricksId string
param datafactoryId string

// Variables
var databricksName = last(split(databricksId, '/'))
var datafactorySubscriptionId = split(datafactoryId, '/')[2]
var datafactoryResourceGroupName = split(datafactoryId, '/')[4]
var datafactoryName = last(split(datafactoryId, '/'))

// Resources
resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' existing = {
  name: databricksName
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryName
  scope: resourceGroup(datafactorySubscriptionId, datafactoryResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(databricks.id, datafactory.id))
  scope: databricks
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: datafactory.identity.principalId
  }
}

// Outputs
