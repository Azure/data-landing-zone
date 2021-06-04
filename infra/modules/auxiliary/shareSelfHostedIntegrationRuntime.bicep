// The module contains a template to share a self hosted integration runtime with another data factory.
targetScope = 'resourceGroup'

// Parameters
param datafactorySourceId string
param datafactorySourceShirId string
param datafactoryDestinationId string

// Variables
var datafactorySourceSubscriptionId = split(datafactorySourceId, '/')[2]
var datafactorySourceResourceGroup = split(datafactorySourceId, '/')[4]
var datafactorySourceShirName = last(split(datafactorySourceShirId, '/'))
var datafactoryDestinationName = last(split(datafactoryDestinationId, '/'))

// Resources
module datafactoryDestinationRoleAssignment 'datafactoryRoleAssignmentDataFactory.bicep' = {
  name: 'datafactoryDestinationRoleAssignment'
  scope: resourceGroup(datafactorySourceSubscriptionId, datafactorySourceResourceGroup)
  params: {
    datafactorySourceId: datafactorySourceId
    datafactoryDestinationId: datafactoryDestinationId
  }
}

resource datafactoryDestination 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: datafactoryDestinationName
}

module deploymentDelay 'delay.bicep' = [for i in range(0,10): {
  name: 'delay-${i}'
  scope: resourceGroup()
  params: {
    deploymentDelayIndex: i
  }
}]

resource datafactorySelfHostedIntegrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: datafactoryDestination
  name: datafactorySourceShirName
  dependsOn: [
    datafactoryDestinationRoleAssignment
    deploymentDelay
  ]
  properties: {
    type: 'SelfHosted'
    description: 'Data Landing Zone - Self-hosted Integration Runtime'
    typeProperties: {
      linkedInfo: {
        authorizationType: 'RBAC'
        resourceId: datafactorySourceShirId
      }
    }
  }
}

// Outputs
