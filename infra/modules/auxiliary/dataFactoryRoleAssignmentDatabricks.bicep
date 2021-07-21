// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to Databricks.
targetScope = 'resourceGroup'

// Parameters
param databricksId string
param datafactoryId string

// Variables
var databricksName = length(split(databricksId, '/')) >= 9 ? last(split(databricksId, '/')) : 'incorrectSegmentLength'
var datafactorySubscriptionId = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[2] : subscription().subscriptionId
var datafactoryResourceGroupName = length(split(datafactoryId, '/')) >= 9 ? split(datafactoryId, '/')[4] : resourceGroup().name
var datafactoryName = length(split(datafactoryId, '/')) >= 9 ? last(split(datafactoryId, '/')) : 'incorrectSegmentLength'

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
    principalType: 'ServicePrincipal'
  }
}

// Outputs
