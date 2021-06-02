// This template is used as a module from the main.bicep template.
// The module contains a template to create logging resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdKeyVault string

// Variables
var keyVault001Name = '${prefix}-vault003'
var logAnalytics001Name = '${prefix}-la001'

// Resources
module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyVault001Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

module logAnalytics001 'services/loganalytics.bicep' = {
  name: 'logAnalytics001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    logAnanalyticsName: logAnalytics001Name
  }
}

resource logAnalytics001IdSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001Name}/logAnalyticsWorkspaceId'
  dependsOn: [
    keyVault001
    logAnalytics001
  ]
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: logAnalytics001.outputs.logAnalyticsWorkspaceCustomerId
  }
}

resource logAnalytics001KeySecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001Name}/logAnalyticsWorkspaceKey'
  dependsOn: [
    keyVault001
    logAnalytics001
  ]
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: listkeys(resourceId('Microsoft.OperationalInsights/workspaces', logAnalytics001Name), '2020-10-01').primarySharedKey
  }
}

// Outputs
