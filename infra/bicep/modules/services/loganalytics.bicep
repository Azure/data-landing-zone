// This template is used to create a Log Analytics workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param logananalyticsName string

// Variables

// Resources
resource loganalytics001 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logananalyticsName
  location: location
  tags: tags
  properties: {
    features: {}
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Disabled'
    retentionInDays: 120
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Outputs
output logAnalyticsWorkspaceId string = loganalytics001.properties.customerId
output logAnalyticsWorkspaceKey string = listkeys(loganalytics001.id, loganalytics001.apiVersion).primarySharedKey
