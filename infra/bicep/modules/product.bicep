// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param vnetId string
param privateSubnetName string
param publicSubnetName string

// Variables

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
    }
  }
}



// Outputs
