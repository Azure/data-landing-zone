// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param datafactoryPrivateDnsZoneIdDataFactory string
param datafactoryPrivateDnsZoneIdPortal string
param databricksVnetId string
param databricksPrivateSubnetName string
param databricksPublicSubnetName string
param privateEndpointSubnetId string
param purviewId string

// Variables
var datafactoryPrivateEndpointNameDatafactory = '${datafactory.name}-datafactory-private-endpoint'
var datafactoryPrivateEndpointNamePortal = '${datafactory.name}-portal-private-endpoint'

// Resources
resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: '${prefix}-domain-databricks'
  location: location
  tags: tags
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: '${prefix}-product-databricks'
    parameters: {
      customVirtualNetworkId: {
        value: databricksVnetId
      }
      customPrivateSubnetName: {
        value: databricksPrivateSubnetName
      }
      customPublicSubnetName: {
        value: databricksPublicSubnetName
      }
      enableNoPublicIp: {
        value: true
      }
      encryption: {
        value: {
          keySource: 'Default'
        }
      }
      prepareEncryption: {
        value: true
      }
      requireInfrastructureEncryption: {
        value: false
      }
    }
  }
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-domain-datafactory'
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

// Todo: Role Assignments and ADF setup with linked services

resource datafactoryPrivateEndpointDatafactory 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: datafactoryPrivateEndpointNameDatafactory
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: datafactoryPrivateEndpointNameDatafactory
        properties: {
          groupIds: [
            'dataFactory'
          ]
          privateLinkServiceId: datafactory.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource datafactoryPrivateEndpointDatafactoryARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${datafactoryPrivateEndpointDatafactory.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointDatafactory.name}-arecord'
        properties: {
          privateDnsZoneId: datafactoryPrivateDnsZoneIdDataFactory
        }
      }
    ]
  }
}

resource datafactoryPrivateEndpointPortal 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: datafactoryPrivateEndpointNamePortal
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: datafactoryPrivateEndpointNamePortal
        properties: {
          groupIds: [
            'portal'
          ]
          privateLinkServiceId: datafactory.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource datafactoryPrivateEndpointPortalARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${datafactoryPrivateEndpointPortal.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointPortal.name}-arecord'
        properties: {
          privateDnsZoneId: datafactoryPrivateDnsZoneIdPortal
        }
      }
    ]
  }
}

// Outputs
