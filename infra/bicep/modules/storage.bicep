// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdDfs string
param privateDnsZoneIdBlob string

// Variables
var domainFileSytemNames = [
  'data'
  'dd001'
  'dd002'
]
var dataProductFileSystemNames = [
  'data'
  'dp001'
  'dp002'
]
var storageRawPrivateEndpointNameBlob = '${storageRaw.name}-blob-private-endpoint'
var storageRawPrivateEndpointNameDfs = '${storageRaw.name}-dfs-private-endpoint'
var storageEnrichedCuratedPrivateEndpointNameBlob = '${storageEnrichedCurated.name}-blob-private-endpoint'
var storageEnrichedCuratedPrivateEndpointNameDfs = '${storageEnrichedCurated.name}-dfs-private-endpoint'
var storageWorkspacePrivateEndpointNameBlob = '${storageWorkspace.name}-blob-private-endpoint'
var storageWorkspacePrivateEndpointNameDfs = '${storageWorkspace.name}-dfs-private-endpoint'

// Resources

/////////////////////////////////////////////////////////////////////////////////////////////////////
// RAW
/////////////////////////////////////////////////////////////////////////////////////////////////////

resource storageRaw 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}-raw', '-', '')
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

resource storageRawManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  name: '${storageRaw.name}/default'
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
                // tierToArchive: {  // Not available for HNS storage yet
                //   // daysAfterLastAccessTimeGreaterThan: 365  // Not available for HNS storage yet
                //   daysAfterModificationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   // daysAfterLastAccessTimeGreaterThan: 730  // Not available for HNS storage yet
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
                // tierToArchive: {  // Not available for HNS storage yet
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

resource storageRawBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  name: '${storageRaw.name}/default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    // automaticSnapshotPolicyEnabled: true  // Not available for HNS storage yet
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

resource storageRawFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for domainFileSytemName in domainFileSytemNames: {
  name: '${storageRaw.name}/default/${domainFileSytemName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageRawPrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageRawPrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageRawPrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageRaw.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageRawPrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageRawPrivateEndpointBlob.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageRawPrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

resource storageRawPrivateEndpointDfs 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageRawPrivateEndpointNameDfs
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageRawPrivateEndpointNameDfs
        properties: {
          groupIds: [
            'dfs'
          ]
          privateLinkServiceId: storageRaw.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageRawPrivateEndpointDfsARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageRawPrivateEndpointDfs.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageRawPrivateEndpointDfs.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDfs
        }
      }
    ]
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// ENRICHED AND CURATED
/////////////////////////////////////////////////////////////////////////////////////////////////////

resource storageEnrichedCurated 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}-encur', '-', '')
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

resource storageEnrichedCuratedManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  name: '${storageEnrichedCurated.name}/default'
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
                // tierToArchive: {  // Not available for HNS storage yet
                //   // daysAfterLastAccessTimeGreaterThan: 365  // Not available for HNS storage yet
                //   daysAfterModificationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   // daysAfterLastAccessTimeGreaterThan: 730  // Not available for HNS storage yet
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
                // tierToArchive: {  // Not available for HNS storage yet
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

resource storageEnrichedCuratedBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  name: '${storageEnrichedCurated.name}/default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    // automaticSnapshotPolicyEnabled: true  // Not available for HNS storage yet
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

resource storageEnrichedCuratedFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for domainFileSytemName in domainFileSytemNames: {
  name: '${storageEnrichedCurated.name}/default/${domainFileSytemName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageEnrichedCuratedPrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageEnrichedCuratedPrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageEnrichedCuratedPrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageEnrichedCurated.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageEnrichedCuratedPrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageEnrichedCuratedPrivateEndpointBlob.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageEnrichedCuratedPrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

resource storageEnrichedCuratedPrivateEndpointDfs 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageEnrichedCuratedPrivateEndpointNameDfs
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageEnrichedCuratedPrivateEndpointNameDfs
        properties: {
          groupIds: [
            'dfs'
          ]
          privateLinkServiceId: storageEnrichedCurated.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageEnrichedCuratedPrivateEndpointDfsARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageEnrichedCuratedPrivateEndpointDfs.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageEnrichedCuratedPrivateEndpointDfs.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDfs
        }
      }
    ]
  }
}


/////////////////////////////////////////////////////////////////////////////////////////////////////
// WORKSPACE
/////////////////////////////////////////////////////////////////////////////////////////////////////

resource storageWorkspace 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}-work', '-', '')
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

resource storageWorkspaceManagementPolicies 'Microsoft.Storage/storageAccounts/managementPolicies@2021-02-01' = {
  name: '${storageWorkspace.name}/default'
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
                // tierToArchive: {  // Not available for HNS storage yet
                //   // daysAfterLastAccessTimeGreaterThan: 365  // Not available for HNS storage yet
                //   daysAfterModificationGreaterThan: 365
                // }
                // delete: {  // Uncomment, if you also want to delete assets after a certain timeframe
                //   // daysAfterLastAccessTimeGreaterThan: 730  // Not available for HNS storage yet
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
                // tierToArchive: {  // Not available for HNS storage yet
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

resource storageWorkspaceBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  name: '${storageWorkspace.name}/default'
  properties: {
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    // automaticSnapshotPolicyEnabled: true  // Not available for HNS storage yet
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

resource storageWorkspaceFileSystems 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = [for dataProductFileSystemName in dataProductFileSystemNames: {
  name: '${storageWorkspace.name}/default/${dataProductFileSystemName}'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]

resource storageWorkspacePrivateEndpointBlob 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageWorkspacePrivateEndpointNameBlob
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageWorkspacePrivateEndpointNameBlob
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storageWorkspace.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageWorkspacePrivateEndpointBlobARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageWorkspacePrivateEndpointBlob.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageWorkspacePrivateEndpointBlob.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdBlob
        }
      }
    ]
  }
}

resource storageWorkspacePrivateEndpointDfs 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: storageWorkspacePrivateEndpointNameDfs
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: storageWorkspacePrivateEndpointNameDfs
        properties: {
          groupIds: [
            'dfs'
          ]
          privateLinkServiceId: storageWorkspace.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource storageWorkspacePrivateEndpointDfsARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${storageWorkspacePrivateEndpointDfs.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${storageWorkspacePrivateEndpointDfs.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDfs
        }
      }
    ]
  }
}

// Outputs
