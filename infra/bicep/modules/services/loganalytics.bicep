// This template is used to create a Log Analytics workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param logAnanalyticsName string

// Variables

// Resources
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: logAnanalyticsName
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
output logAnalyticsWorkspaceCustomerId string = logAnalytics.properties.customerId
