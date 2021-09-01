// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a SQL Server and Database.
targetScope = 'resourceGroup'

// Parameters
param location string
param sqlserverName string
param tags object
param subnetId string
param administratorUsername string = 'SqlServerMainUser'
@secure()
param administratorPassword string
param sqlserverAdminGroupName string = ''
param sqlserverAdminGroupObjectID string = ''
param privateDnsZoneIdSqlServer string = ''

// Variables
var sqlserverAdfMetastoreDbName = 'AdfMetastoreDb'
var sqlserverPrivateEndpointName = '${sqlserver.name}-private-endpoint'

// Resources
resource sqlserver 'Microsoft.Sql/servers@2020-11-01-preview' = {
  name: sqlserverName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorUsername
    administratorLoginPassword: administratorPassword
    administrators: {}
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    version: '12.0'
  }
}

resource sqlserverAdministrators 'Microsoft.Sql/servers/administrators@2020-11-01-preview' = if (!empty(sqlserverAdminGroupName) && !empty(sqlserverAdminGroupObjectID)) {
  parent: sqlserver
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlserverAdminGroupName
    sid: sqlserverAdminGroupObjectID
    tenantId: subscription().tenantId
  }
}

resource sqlserverAdfMetastoreDb 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  parent: sqlserver
  name: sqlserverAdfMetastoreDbName
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
    zoneRedundant: false
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

resource sqlserverPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdSqlServer)) {
  parent: sqlserverPrivateEndpoint
  name: 'default'
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

// Outputs
output sqlServerId string = sqlserver.id
output sqlServerDatabaseName string = sqlserverAdfMetastoreDbName
