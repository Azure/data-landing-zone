// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to deploy the log analytics secrets to the .
targetScope = 'resourceGroup'

// Parameters
param keyVaultId string
param logAnalyticsId string

// Variables
var keyVaultName = length(split(keyVaultId, '/')) >= 9 ? last(split(keyVaultId, '/')) : 'incorrectSegmentLength'
var logAnalyticsSubscriptionId = length(split(logAnalyticsId, '/')) >= 9 ? split(logAnalyticsId, '/')[2] : subscription().subscriptionId
var logAnalyticsResourceGroupName = length(split(logAnalyticsId, '/')) >= 9 ? split(logAnalyticsId, '/')[4] : resourceGroup().name
var logAnalyticsName = length(split(logAnalyticsId, '/')) >= 9 ? last(split(logAnalyticsId, '/')) : 'incorrectSegmentLength'
var logAnalyticsWorkspaceIdSecretName = '${logAnalyticsName}Id'
var logAnalyticsWorkspaceKeySecretName = '${logAnalyticsName}Key'

// Resources
resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(logAnalyticsSubscriptionId, logAnalyticsResourceGroupName)
}

resource logAnalytics001IdSecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: logAnalyticsWorkspaceIdSecretName
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: logAnalytics.properties.customerId
  }
}

resource logAnalytics001KeySecretDeployment 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  parent: keyVault
  name: logAnalyticsWorkspaceKeySecretName
  properties: {
    attributes: {
      enabled: true
    }
    contentType: 'text/plain'
    value: listkeys(logAnalytics.id, logAnalytics.apiVersion).primarySharedKey
  }
}

// Outputs
output logAnalyticsWorkspaceIdSecretName string = logAnalyticsWorkspaceIdSecretName
output logAnalyticsWorkspaceKeySecretName string = logAnalyticsWorkspaceKeySecretName
