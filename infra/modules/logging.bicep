// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template.
// The module contains a template to create logging resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdKeyVault string = ''

// Variables
var keyVault001Name = '${prefix}-vault003'
var logAnalytics001Name = '${prefix}-la001'

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

module logAnalytics001 'services/loganalytics.bicep' = {
  name: 'logAnalytics001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    logAnanalyticsName: logAnalytics001Name
  }
}

module logAnalytics001SecretDeployment 'auxiliary/logAnalyticsSecretDeployment.bicep' = {
  name: 'logAnalytics001SecretDeployment'
  scope: resourceGroup()
  params: {
    keyVaultId: keyVault001.outputs.keyvaultId
    logAnalyticsId: logAnalytics001.outputs.logAnalyticsWorkspaceId
  }
}

// Outputs
output logAnalytics001WorkspaceKeyVaultId string = keyVault001.outputs.keyvaultId
output logAnalytics001WorkspaceIdSecretName string = logAnalytics001SecretDeployment.outputs.logAnalyticsWorkspaceIdSecretName
output logAnalytics001WorkspaceKeySecretName string = logAnalytics001SecretDeployment.outputs.logAnalyticsWorkspaceKeySecretName
