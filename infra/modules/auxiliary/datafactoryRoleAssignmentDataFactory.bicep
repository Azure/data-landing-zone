// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to assign a datafactory as contributor to another data factory.
targetScope = 'resourceGroup'

// Parameters
param datafactorySourceId string
param datafactoryDestinationId string

// Variables
var datafactorySourceName = length(split(datafactorySourceId, '/')) >= 9 ? last(split(datafactorySourceId, '/')) : 'incorrectSegmentLength'
var datafactoryDestinationSubscriptionId = length(split(datafactoryDestinationId, '/')) >= 9 ? split(datafactoryDestinationId, '/')[2] : subscription().subscriptionId
var datafactoryDestinationResourceGroup = length(split(datafactoryDestinationId, '/')) >= 9 ? split(datafactoryDestinationId, '/')[4] : resourceGroup().name
var datafactoryDestinationName = length(split(datafactoryDestinationId, '/')) >= 9 ? last(split(datafactoryDestinationId, '/')) : 'incorrectSegmentLength'

// Resources
resource datafactorySource 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactorySourceName
}

resource datafactoryDestination 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryDestinationName
  scope: resourceGroup(datafactoryDestinationSubscriptionId, datafactoryDestinationResourceGroup)
}

resource datafactoryRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(datafactorySource.id, datafactoryDestination.id))
  scope: datafactorySource
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: datafactoryDestination.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
