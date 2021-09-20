// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create an EventHub Namespace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param eventhubnamespaceName string
@minValue(1)
@maxValue(20)
param eventhubnamespaceMinThroughput int = 1
@minValue(1)
@maxValue(20)
param eventhubnamespaceMaxThroughput int = 2
param privateDnsZoneIdEventhubNamespace string = ''

// Variables
var eventhubNamespacePrivateEndpointName = '${eventhubNamespace.name}-private-endpoint'

// Resources
resource eventhubNamespace 'Microsoft.EventHub/namespaces@2021-01-01-preview' = {
  name: eventhubnamespaceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: eventhubnamespaceMinThroughput
  }
  properties: {
    isAutoInflateEnabled: true
    kafkaEnabled: true
    maximumThroughputUnits: eventhubnamespaceMaxThroughput
    zoneRedundant: true
  }
}

resource eventhubNamespaceNetworkRuleSets 'Microsoft.EventHub/namespaces/networkRuleSets@2021-06-01-preview' = {
  name: 'default'
  parent: eventhubNamespace
  properties: {
    defaultAction: 'Deny'
    ipRules: []
    virtualNetworkRules: []
    publicNetworkAccess: 'Disabled'
    trustedServiceAccessEnabled: false
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

resource eventhubNamespacePrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdEventhubNamespace)) {
  parent: eventhubNamespacePrivateEndpoint
  name: 'default'
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
