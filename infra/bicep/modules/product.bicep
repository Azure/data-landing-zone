// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param administratorPassword string
param synapseSqlAdminGroupName string
param synapseSqlAdminGroupObjectID string
param synapseDefaultStorageAccountFileSystemId string
param synapseComputeSubnetId string
param synapsePrivateDnsZoneIdSql string
param synapsePrivateDnsZoneIdDev string
param databricksVnetId string
param databricksPrivateSubnetName string
param databricksPublicSubnetName string
param privateEndpointSubnetId string
param purviewId string

// Variables
var synapseDefaultStorageAccountFileSystemName = split(synapseDefaultStorageAccountFileSystemId, '/')[-1]
var synapseDefaultStorageAccountName = split(synapseDefaultStorageAccountFileSystemId, '/')[7]
var synapsePrivateEndpointNameSql = '${synapse.name}-sql-private-endpoint'
var synapsePrivateEndpointNameSqlOnDemand = '${synapse.name}-sqlondemand-private-endpoint'
var synapsePrivateEndpointNameDev = '${synapse.name}-dev-private-endpoint'

// Resources
resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: '${prefix}-product-databricks'
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

resource synapse 'Microsoft.Synapse/workspaces@2021-03-01' = {
  name: '${prefix}-product-synapse'
  location: location
  tags: tags
  properties: {
    defaultDataLakeStorage: {
      accountUrl: 'https://${synapseDefaultStorageAccountName}.dfs.core.windows.net'
      filesystem: synapseDefaultStorageAccountFileSystemName
    }
    managedResourceGroupName: '${prefix}-product-synapse'
    managedVirtualNetwork: 'default'
    managedVirtualNetworkSettings: {
      allowedAadTenantIdsForLinking: []
      linkedAccessCheckOnTargetResource: true
      preventDataExfiltration: true
    }
    publicNetworkAccess: 'Disabled'
    purviewConfiguration: {
      purviewResourceId: purviewId
    }
    sqlAdministratorLogin: 'SqlServerMainUser'
    sqlAdministratorLoginPassword: administratorPassword
    virtualNetworkProfile: {
      computeSubnetId: synapseComputeSubnetId
    }
  }
}

resource synapseManagedIdentitySqlControlSettings 'Microsoft.Synapse/workspaces/managedIdentitySqlControlSettings@2021-03-01' = {
  name: '${synapse.name}/default'
  properties: {
    grantSqlControlToManagedIdentity: {
      desiredState: 'Enabled'
    }
  }
}

resource synapseAadAdministrators 'Microsoft.Synapse/workspaces/administrators@2021-03-01' = {
  name: '${synapse.name}/activeDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: synapseSqlAdminGroupName
    sid: synapseSqlAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}

resource synapseRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(uniqueString(synapseDefaultStorageAccountFileSystemId, synapse.id))
  scope: 'Microsoft.Storage/storageAccounts/${synapseDefaultStorageAccountName}/blobServices/default/containers/${synapseDefaultStorageAccountFileSystemName}'
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: synapse.identity.principalId
  }
}

resource synapsePrivateEndpointSql 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: synapsePrivateEndpointNameSql
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: synapsePrivateEndpointNameSql
        properties: {
          groupIds: [
            'Sql'
          ]
          privateLinkServiceId: synapse.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource synapsePrivateEndpointSqlARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${synapsePrivateEndpointSql.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${synapsePrivateEndpointSql.name}-arecord'
        properties: {
          privateDnsZoneId: synapsePrivateDnsZoneIdSql
        }
      }
    ]
  }
}

resource synapsePrivateEndpointSqlOnDemand 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: synapsePrivateEndpointNameSqlOnDemand
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: synapsePrivateEndpointNameSqlOnDemand
        properties: {
          groupIds: [
            'SqlOnDemand'
          ]
          privateLinkServiceId: synapse.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource synapsePrivateEndpointSqlOnDemandARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${synapsePrivateEndpointSqlOnDemand.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${synapsePrivateEndpointSqlOnDemand.name}-arecord'
        properties: {
          privateDnsZoneId: synapsePrivateDnsZoneIdSql
        }
      }
    ]
  }
}

resource synapsePrivateEndpointDev 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: synapsePrivateEndpointNameDev
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: synapsePrivateEndpointNameDev
        properties: {
          groupIds: [
            'Dev'
          ]
          privateLinkServiceId: synapse.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource synapsePrivateEndpointDevARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${synapsePrivateEndpointDev.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${synapsePrivateEndpointDev.name}-arecord'
        properties: {
          privateDnsZoneId: synapsePrivateDnsZoneIdDev
        }
      }
    ]
  }
}

// Outputs
