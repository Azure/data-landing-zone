// This template is used to create a Databricks workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param eventhubnamespaceName string
param privateDnsZoneIdEventhubNamespace string

// Variables
var eventhubNamespacePrivateEndpointName = '${eventhubNamespace.name}-private-endpoint'

// Resources
resource eventhubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: eventhubnamespaceName
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

// resource eventhub001 'Microsoft.EventHub/namespaces/eventhubs@2021-01-01-preview' = {  // Uncomment to deploy an Event Hub in the namespace
//   parent: eventhubNamespace
//   name: 'default'
//   properties: {
//     captureDescription: {
//       destination: {
//         name: 'default'
//         properties: {
//           archiveNameFormat: ''
//           blobContainer: ''
//           storageAccountResourceId: ''
//         }
//       }
//       enabled: true
//       encoding: 'Avro'
//       intervalInSeconds: 900
//       sizeLimitInBytes: 10485760
//       skipEmptyArchives: true
//     }
//     messageRetentionInDays: 3
//     partitionCount: 1
//     status: 'Active'
//   }
// }

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
      id: subnetId
    }
  }
}

resource eventhubNamespacePrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  parent: eventhubNamespacePrivateEndpoint
  name: 'aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${eventhubNamespacePrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdEventhubNamespace
        }
      }
    ]
  }
}

// Outputs
