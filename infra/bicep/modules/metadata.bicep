// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
@secure()
param administratorPassword string
param sqlserverAdminGroupName string
param sqlserverAdminGroupObjectID string
param mysqlserverAdminGroupName string
param mysqlserverAdminGroupObjectID string
param privateDnsZoneIdSqlServer string
param privateDnsZoneIdMySqlServer string
param privateDnsZoneIdKeyVault string

// Variables
var administratorUsername = 'SqlServerMainUser'
var keyVault001PrivateEndpointName = '${keyVault001.name}-private-endpoint'
var keyVault002PrivateEndpointName = '${keyVault002.name}-private-endpoint'
var sqlserverPrivateEndpointName = '${sqlserver.name}-private-endpoint'
var mysqlserverPrivateEndpointName = '${mysqlserver.name}-private-endpoint'

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

resource keyVault002 'Microsoft.KeyVault/vaults@2021-04-01-preview' = {
  name: '${prefix}-vault002'
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

resource keyVault002PrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: keyVault002PrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: keyVault002PrivateEndpointName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault002.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource keyVault002PrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${keyVault002PrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${keyVault002PrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdKeyVault
        }
      }
    ]
  }
}

resource sqlserver 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: '${prefix}-sqlserver'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorUsername
    administratorLoginPassword: administratorPassword
    administrators: {
      azureADOnlyAuthentication: true
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    version: '12.0'
  }
}

resource sqlserverAdministrators 'Microsoft.Sql/servers/administrators@2020-11-01-preview' = if (sqlserverAdminGroupName != null && sqlserverAdminGroupObjectID != null) {
  name: '${sqlserver.name}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlserverAdminGroupName
    sid: sqlserverAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}

resource sqlserverPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: sqlserverPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: sqlserverPrivateEndpointName
        properties: {
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceId: sqlserver.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource sqlserverPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${sqlserverPrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${sqlserverPrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdSqlServer
        }
      }
    ]
  }
}

resource sqlserverAdfMetastoreDb 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  name: '${sqlserver.name}/AdfMetastoreDb'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    autoPauseDelay: -1
    catalogCollation: 'DATABASE_DEFAULT'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    readScale: 'Disabled'
    highAvailabilityReplicaCount: 0
    licenseType: 'LicenseIncluded'
    maxSizeBytes: 524288000
    minCapacity: 1
    requestedBackupStorageRedundancy: 'Geo'
    zoneRedundant: true
  }
}

resource mysqlserver 'Microsoft.DBForMySQL/servers@2017-12-01' = {
  name: '${prefix}-mysqlserver'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'GP_Gen5_2'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 2
    size: '5120'
  }
  properties: {
    administratorLogin: administratorUsername
    administratorLoginPassword: administratorPassword
    createMode: 'Default'
    infrastructureEncryption: 'Disabled'
    minimalTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    sslEnforcement: 'Enabled'
    storageProfile: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Enabled'
      storageAutogrow: 'Enabled'
      storageMB: 5120
    }
    version: '5.7'
  }
}

resource mysqlserverConfiguration001 'Microsoft.DBForMySQL/servers/configurations@2017-12-01' = {
  name: '${mysqlserver.name}/lower_case_table_names'
  properties: {
    value: '2'
    source: 'user-override'
  }
}

resource mysqlserverHiveMetastoreDb 'Microsoft.DBForMySQL/servers/databases@2017-12-01' = {
  name: '${mysqlserver.name}/HiveMetastoreDb'
  properties: {
    charset: 'latin1'
    collation: 'latin1_swedish_ci'
  }
}

resource mysqlserverAdministrators 'Microsoft.DBForMySQL/servers/administrators@2017-12-01' = {
  name: '${mysqlserver.name}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: mysqlserverAdminGroupName
    sid: mysqlserverAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}

resource mysqlserverPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: mysqlserverPrivateEndpointName
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: mysqlserverPrivateEndpointName
        properties: {
          groupIds: [
            'mysqlServer'
          ]
          privateLinkServiceId: mysqlserver.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource mysqlserverPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${mysqlserverPrivateEndpoint.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${mysqlserverPrivateEndpoint.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdMySqlServer
        }
      }
    ]
  }
}

resource mysqlserverUsernameSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002.name}/${mysqlserver.name}Username'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: administratorUsername
  }
}

resource mysqlserverPasswordSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002.name}/${mysqlserver.name}Password'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: administratorPassword
  }
}

resource mysqlserverConnectionStringSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002.name}/${mysqlserver.name}ConnectionString'
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: 'jdbc:mysql://${mysqlserver.name}.mysql.database.azure.com:3306/${mysqlserverHiveMetastoreDb.name}?useSSL=true&requireSSL=false&enabledSslProtocolSuites=TLSv1.2'
  }
}

// Outputs
