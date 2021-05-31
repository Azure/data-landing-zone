// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdKeyVault string

// Variables
var keyVault001PrivateEndpointName = '${keyVault001.name}-private-endpoint'

// Resources
resource keyVault001 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: '${prefix}-vault001'
  location: location
  tags: tags
  properties: {
    accessPolicies: []
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

resource keyVault001PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: keyVault001PrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: keyVault001PrivateEndpointName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource keyVault001PrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${keyVault001PrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${keyVault001PrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdKeyVault
        }
      }
    ]
  }
}

resource loganalytics001 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: '${prefix}-la001'
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

resource logAnalyticsIdSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001.name}/logAnalyticsWorkspaceId'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: loganalytics001.properties.customerId
  }
}

resource logAnalyticsKeySecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault001.name}/logAnalyticsWorkspaceKey'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: listkeys(loganalytics001.id, loganalytics001.apiVersion).primarySharedKey
  }
}

// Outputs
