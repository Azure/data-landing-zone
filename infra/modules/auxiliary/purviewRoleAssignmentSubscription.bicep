// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to Databricks.
targetScope = 'subscription'

// Parameters
param purviewId string

// Variables
var purviewSubscriptionId = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[2] : subscription().subscriptionId
var purviewResourceGroupName = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[4] : 'incorrectSegmentLength'
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'

// Resources
resource purview 'Microsoft.Purview/accounts@2021-07-01' existing = {
  name: purviewName
  scope: resourceGroup(purviewSubscriptionId, purviewResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(subscription().subscriptionId, purview.id))
  scope: subscription()
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: purview.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
