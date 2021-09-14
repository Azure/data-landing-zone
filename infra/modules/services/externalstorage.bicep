// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a storage account where the access key needs to be shared.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param storageName string
param privateDnsZoneIdBlob string = ''
param fileSytemNames array = [
  'data'
]

// Variables
var storageNameCleaned = replace(storageName, '-', '')
var storageExternalPrivateEndpointNameBlob = '${storageExternal.name}-blob-private-endpoint'

// Resources
resource storageExternal 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
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
    isHnsEnabled: false
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
    // routingPreference: {  // Not supported for thsi account
    //   routingChoice: 'MicrosoftRouting'
    //   publishInternetEndpoints: false
    //   publishMicrosoftEndpoints: false
    // }
    supportsHttpsTrafficOnly: true
  }
}

resource storageExternalManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  parent: storageExternal
  name: 'default'
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
                // enableAutoTierToHotFromCool: true  // Not available for this configuration
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

resource storageExternalBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storageExternal
  name: 'default'
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

resource storageExternalFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for fileSytemName in fileSytemNames: {
  parent: storageExternalBlobServices
  name: fileSytemName
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageExternalPrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageExternalPrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageExternalPrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageExternal.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageExternalPrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdBlob)) {
  parent: storageExternalPrivateEndpointBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageExternalPrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

// Outputs
