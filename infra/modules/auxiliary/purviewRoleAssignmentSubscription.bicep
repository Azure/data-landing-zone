// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a role assignment to a Subscription.
targetScope = 'subscription'

// Parameters
param purviewId string
@allowed([
  'Reader'
  'StorageBlobDataReader'
])
param role string

// Variables
var purviewSubscriptionId = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[2] : subscription().subscriptionId
var purviewResourceGroupName = length(split(purviewId, '/')) >= 9 ? split(purviewId, '/')[4] : 'incorrectSegmentLength'
var purviewName = length(split(purviewId, '/')) >= 9 ? last(split(purviewId, '/')) : 'incorrectSegmentLength'
var roles = {
  'Reader': 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  'StorageBlobDataReader': '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

// Resources
resource purview 'Microsoft.Purview/accounts@2021-07-01' existing = {
  name: purviewName
  scope: resourceGroup(purviewSubscriptionId, purviewResourceGroupName)
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(subscription().subscriptionId, purview.id, roles[role]))
  scope: subscription()
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roles[role])
    principalId: purview.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
