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
    logananalyticsName: logAnalytics001Name
  }
}

resource logAnalytics001Ref 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: logAnalytics001Name
}

resource logAnalytics001IdSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001.name}/logAnalyticsWorkspaceId'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: logAnalytics001Ref.properties.customerId
  }
}

resource logAnalytics001KeySecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001.name}/logAnalyticsWorkspaceKey'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: listkeys(logAnalytics001Ref.id, logAnalytics001Ref.apiVersion).primarySharedKey
  }
}

// Outputs
