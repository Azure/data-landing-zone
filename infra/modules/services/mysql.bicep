// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a MySQL Server and Database.
targetScope = 'resourceGroup'

// Parameters
param location string
param mysqlserverName string
param tags object
param subnetId string
param administratorUsername string = 'SqlServerMainUser'
@secure()
param administratorPassword string
param mysqlserverAdminGroupName string = ''
param mysqlserverAdminGroupObjectID string = ''
param privateDnsZoneIdMySqlServer string = ''

// Variables
var mySqlServerDatabaseName = 'HiveMetastoreDb'
var mysqlserverPrivateEndpointName = '${mysqlserver.name}-private-endpoint'

// Resources
resource mysqlserver 'Microsoft.DBForMySQL/servers@2017-12-01' = {
  name: mysqlserverName
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
  parent: mysqlserver
  name: 'lower_case_table_names'
  properties: {
    value: '2'
    source: 'user-override'
  }
}

resource mysqlserverHiveMetastoreDb 'Microsoft.DBForMySQL/servers/databases@2017-12-01' = {
  parent: mysqlserver
  name: mySqlServerDatabaseName
  properties: {
    charset: 'latin1'
    collation: 'latin1_swedish_ci'
  }
}

resource mysqlserverAdministrators 'Microsoft.DBForMySQL/servers/administrators@2017-12-01' = if (!empty(mysqlserverAdminGroupName) && !empty(mysqlserverAdminGroupObjectID)) {
  parent: mysqlserver
  name: 'activeDirectory'
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

resource mysqlserverPrivateEndpointARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdMySqlServer)) {
  parent: mysqlserverPrivateEndpoint
  name: 'default'
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

// Outputs
output mySqlServerId string = mysqlserver.id
output mySqlServerDatabaseName string = mySqlServerDatabaseName
