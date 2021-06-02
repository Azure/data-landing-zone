// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param administratorUsername string = 'SqlServerMainUser'
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
var keyVault001Name = '${prefix}-vault001'
var keyVault002Name = '${prefix}-vault002'
var sqlServer001Name = '${prefix}-sqlserver001'
var mySqlServer001Name = '${prefix}-mysqlserver001'

// Resources
module keyVault001 'services/keyvault.bicep' = {
  name: 'keyVault001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyVault001Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

module keyVault002 'services/keyvault.bicep' = {
  name: 'keyVault002'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    keyvaultName: keyVault002Name
    privateDnsZoneIdKeyVault: privateDnsZoneIdKeyVault
  }
}

module sqlServer001 'services/sql.bicep' = {
  name: 'sqlserver001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    sqlserverAdminGroupName: ''
    sqlserverAdminGroupObjectID: ''
    sqlserverName: sqlServer001Name
    privateDnsZoneIdSqlServer: privateDnsZoneIdSqlServer
  }
}

module mySqlServer001 'services/mysql.bicep' = {
  name: 'mysqlserver001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    mysqlserverName: mySqlServer001Name
    administratorUsername: administratorUsername
    administratorPassword: administratorPassword
    mysqlserverAdminGroupName: ''
    mysqlserverAdminGroupObjectID: ''
    privateDnsZoneIdMySqlServer: privateDnsZoneIdMySqlServer
  }
}

resource mysqlserver001UsernameSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002Name}/${mySqlServer001Name}Username'
  dependsOn: [
    keyVault002
  ]
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: administratorUsername
  }
}

resource mysqlserver001PasswordSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002Name}/${mySqlServer001Name}Password'
  dependsOn: [
    keyVault002
  ]
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: administratorPassword
  }
}

resource mysqlserver001ConnectionStringSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: '${keyVault002Name}/${mySqlServer001Name}ConnectionString'
  dependsOn: [
    keyVault002
  ]
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: 'jdbc:mysql://${mySqlServer001Name}.mysql.database.azure.com:3306/${mySqlServer001.outputs.mySqlServerDatabaseName}?useSSL=true&requireSSL=false&enabledSslProtocolSuites=TLSv1.2'
  }
}

// Outputs
