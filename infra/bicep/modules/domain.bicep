// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param storageAccountRawFileSystemId string
param storageAccountEnrichedCuratedFileSystemId string
param datafactoryPrivateDnsZoneIdDataFactory string
param datafactoryPrivateDnsZoneIdPortal string
param databricksVnetId string
param databricksPrivateSubnetName string
param databricksPublicSubnetName string
param privateEndpointSubnetId string
param purviewId string
param eventhubPrivateDnsZoneId string

// Variables
var storageAccountRawSubscriptionId = split(storageAccountRawFileSystemId, '/')[2]
var storageAccountRawResourceGroupName = split(storageAccountRawFileSystemId, '/')[4]
var storageAccountEnrichedCuratedSubscriptionId = split(storageAccountEnrichedCuratedFileSystemId, '/')[2]
var storageAccountEnrichedCuratedResourceGroupName = split(storageAccountEnrichedCuratedFileSystemId, '/')[4]
var datafactoryPrivateEndpointNameDatafactory = '${datafactory.name}-datafactory-private-endpoint'
var datafactoryPrivateEndpointNamePortal = '${datafactory.name}-portal-private-endpoint'
var eventhubNamespacePrivateEndpointName = '${eventhubNamespace.name}-private-endpoint'

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

resource eventhubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: '${prefix}-domain-eventhub'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: true
    kafkaEnabled: true
    maximumThroughputUnits: 1
    zoneRedundant: true
  }
}

resource eventhub 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = if (false) { // Set to true to deploy an Event Hub in the namespace
  name: 'default'
  parent: eventhubNamespace
  properties: {
    captureDescription: {
      destination: {
        name: 'default'
        properties: {
          archiveNameFormat: ''
          blobContainer: ''
          storageAccountResourceId: ''
        }
      }
      enabled: true
      encoding: 'Avro'
      intervalInSeconds: 900
      sizeLimitInBytes: 10485760
      skipEmptyArchives: true
    }
    messageRetentionInDays: 3
    partitionCount: 1
    status: 'Active'
  }
}

resource eventhubNamespacePrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: eventhubNamespacePrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: eventhubNamespacePrivateEndpointName
        properties: {
          groupIds: [
            'namespace'
          ]
          privateLinkServiceId: eventhubNamespace.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource eventhubNamespacePrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${eventhubNamespacePrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${eventhubNamespacePrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: eventhubPrivateDnsZoneId
        }
      }
    ]
  }
}

module datafactoryStorageRawRoleAssignment 'domain/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactoryStorageRawRoleAssignment'
  scope: resourceGroup(storageAccountRawSubscriptionId, storageAccountRawResourceGroupName)
  params: {
    datafactoryId: datafactory.id
    storageAccountFileSystemId: storageAccountRawFileSystemId
  }
}

module datafactoryStorageEnrichedCuratedRoleAssignment 'domain/dataFactoryRoleAssignmentStorage.bicep' = {
  name: 'datafactoryStorageEnrichedCuratedRoleAssignment'
  scope: resourceGroup(storageAccountEnrichedCuratedSubscriptionId, storageAccountEnrichedCuratedResourceGroupName)
  params: {
    datafactoryId: datafactory.id
    storageAccountFileSystemId: storageAccountEnrichedCuratedFileSystemId
  }
}

module datafactoryDatabricksRoleAssignment 'domain/dataFactoryRoleAssignmentDatabricks.bicep' = {
  name: 'datafactoryDatabricksRoleAssignment'
  scope: resourceGroup()
  params: {
    datafactoryId: datafactory.id
    databricksId: databricks.id
  }
}

// Todo: Role Assignments and ADF setup with linked services

// Outputs
