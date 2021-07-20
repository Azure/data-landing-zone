// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Databricks workspace.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param databricksName string
param vnetId string
param privateSubnetName string
param publicSubnetName string

// Variables

// Resources
resource databricks 'Microsoft.Databricks/workspaces@2018-04-01' = {
  name: databricksName
  location: location
  tags: tags
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: '${subscription().id}/resourceGroups/${databricksName}-rg'
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      customPrivateSubnetName: {
        value: privateSubnetName
      }
      customPublicSubnetName: {
        value: publicSubnetName
      }
      enableNoPublicIp: {
        value: true
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

// Outputs
output databricksId string = databricks.id
output databricksWorkspaceUrl string = databricks.properties.workspaceUrl
output databricksApiUrl string = 'https://${location}.azuredatabricks.net'
