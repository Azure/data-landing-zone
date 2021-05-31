// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdBlob string

// Variables
var fileSytemNames = [
  'data'
]
var storageExternal001PrivateEndpointNameBlob = '${storageExternal001.name}-blob-private-endpoint'

// Resources
resource storageExternal001 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}-external001', '-', '')
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_ZRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: true
    isNfsV3Enabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'Metrics'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
    }
    supportsHttpsTrafficOnly: true
  }
}

resource storageExternal001ManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  name: '${storageExternal001.name}/default'
  properties: {
    policy: {
      rules: [
        {
          enabled: true
          name: 'default'
          type: 'Lifecycle'
          definition: {
            actions: {
              baseBlob: {
                enableAutoTierToHotFromCool: true
                tierToCool: {
                  // daysAfterLastAccessTimeGreaterThan: 90  // Not available for HNS storage yet
                  daysAfterModificationGreaterThan: 90
                }
                // tierToArchive: {  // Uncomment, if you want to move data to the archive tier
                //   // daysAfterLastAccessTimeGreaterThan: 365
                //   daysAfterModificationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   // daysAfterLastAccessTimeGreaterThan: 730
                //   daysAfterModificationGreaterThan: 730
                // }
              }
              snapshot: {
                tierToCool: {
                  daysAfterCreationGreaterThan: 90
                }
                // tierToArchive: {  // Not available for HNS storage yet
                //   daysAfterCreationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   daysAfterCreationGreaterThan: 730
                // }
              }
              version: {
                tierToCool: {
                  daysAfterCreationGreaterThan: 90
                }
                // tierToArchive: {  // Uncomment, if you want to move data to the archive tier
                //   daysAfterCreationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   daysAfterCreationGreaterThan: 730
                // }
              }
            }
            filters: {
              blobIndexMatch: []
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: []
            }
          }
        }
      ]
    }
  }
}

resource storageExternal001BlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  name: '${storageExternal001.name}/default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    // automaticSnapshotPolicyEnabled: true  // Uncomment, if you want to enable addition features on the storage account
    // changeFeed: {
    //   enabled: true
    //   retentionInDays: 7
    // }
    // defaultServiceVersion: ''
    // deleteRetentionPolicy: {
    //   enabled: true
    //   days: 7
    // }
    // isVersioningEnabled: true
    // lastAccessTimeTrackingPolicy: {
    //   name: 'AccessTimeTracking'
    //   enable: true
    //   blobType: [
    //     'blockBlob'
    //   ]
    //   trackingGranularityInDays: 1
    // }
    // restorePolicy: {
    //   enabled: true
    //   days: 7
    // }
  }
}

resource storageExternal001FileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for fileSytemName in fileSytemNames: {
  name: '${storageExternal001.name}/default/${fileSytemName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageExternal001PrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageExternal001PrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageExternal001PrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageExternal001.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageExternal001PrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageExternal001PrivateEndpointBlob.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageExternal001PrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

// Outputs
