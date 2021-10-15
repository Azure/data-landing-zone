// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Data Factory.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param datafactoryName string
param privateDnsZoneIdDataFactory string = ''
param privateDnsZoneIdDataFactoryPortal string = ''

param purviewId string = ''
param purviewManagedStorageId string = ''
param purviewManagedEventHubId string = ''
param storageRawId string
param storageEnrichedCuratedId string
param databricks001Id string
param databricks001WorkspaceUrl string
param keyVault001Id string
param sqlServer001Id string
param sqlDatabase001Name string

// Variables
var storageRawName = length(split(storageRawId, '/')) >= 9 ? last(split(storageRawId, '/')) : 'incorrectSegmentLength'
var storageEnrichedCuratedName = length(split(storageEnrichedCuratedId, '/')) >= 9 ? last(split(storageEnrichedCuratedId, '/')) : 'incorrectSegmentLength'
var databricks001Name = length(split(databricks001Id, '/')) >= 9 ? last(split(databricks001Id, '/')) : 'incorrectSegmentLength'
var keyVault001Name = length(split(keyVault001Id, '/')) >= 9 ? last(split(keyVault001Id, '/')) : 'incorrectSegmentLength'
var sqlServer001Name = length(split(sqlServer001Id, '/')) >= 9 ? last(split(sqlServer001Id, '/')) : 'incorrectSegmentLength'
var datafactoryDefaultManagedVnetIntegrationRuntimeName = 'AutoResolveIntegrationRuntime'
var datafactoryPrivateEndpointNameDatafactory = '${datafactory.name}-datafactory-private-endpoint'
var datafactoryPrivateEndpointNamePortal = '${datafactory.name}-portal-private-endpoint'

// Resources
resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: datafactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    globalParameters: {}
    publicNetworkAccess: 'Disabled'
    purviewConfiguration: {
      purviewResourceId: purviewId
    }
  }
}

resource datafactoryPrivateEndpointDatafactory 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: datafactoryPrivateEndpointNameDatafactory
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: datafactoryPrivateEndpointNameDatafactory
        properties: {
          groupIds: [
            'dataFactory'
          ]
          privateLinkServiceId: datafactory.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource datafactoryPrivateEndpointDatafactoryARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdDataFactory)) {
  parent: datafactoryPrivateEndpointDatafactory
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointDatafactory.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDataFactory
        }
      }
    ]
  }
}

resource datafactoryPrivateEndpointPortal 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: datafactoryPrivateEndpointNamePortal
  location: location
  tags: tags
  properties: {
    manualPrivateLinkServiceConnections: []
    privateLinkServiceConnections: [
      {
        name: datafactoryPrivateEndpointNamePortal
        properties: {
          groupIds: [
            'portal'
          ]
          privateLinkServiceId: datafactory.id
          requestMessage: ''
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

resource datafactoryPrivateEndpointPortalARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (!empty(privateDnsZoneIdDataFactoryPortal)) {
  parent: datafactoryPrivateEndpointPortal
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointPortal.name}-arecord'
        properties: {
          privateDnsZoneId: privateDnsZoneIdDataFactoryPortal
        }
      }
    ]
  }
}

resource datafactoryManagedVirtualNetwork 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  parent: datafactory
  name: 'default'
  properties: {}
}

resource datafactoryManagedIntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: datafactory
  name: datafactoryDefaultManagedVnetIntegrationRuntimeName
  properties: {
    type: 'Managed'
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: datafactoryManagedVirtualNetwork.name
    }
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
    }
  }
}

resource datafactoryPurviewManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if(!empty(purviewId)) {
  parent: datafactoryManagedVirtualNetwork
  name: 'Purview'
  properties: {
    fqdns: []
    groupId: 'account'
    privateLinkResourceId: purviewId
  }
}

resource datafactoryPurviewBlobManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if(!empty(purviewManagedStorageId)) {
  parent: datafactoryManagedVirtualNetwork
  name: 'Purview_blob'
  properties: {
    fqdns: []
    groupId: 'blob'
    privateLinkResourceId: purviewManagedStorageId
  }
}

resource datafactoryPurviewQueueManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if(!empty(purviewManagedStorageId)) {
  parent: datafactoryManagedVirtualNetwork
  name: 'Purview_queue'
  properties: {
    fqdns: []
    groupId: 'queue'
    privateLinkResourceId: purviewManagedStorageId
  }
}

resource datafactoryPurviewNamespaceManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = if(!empty(purviewManagedEventHubId)) {
  parent: datafactoryManagedVirtualNetwork
  name: 'Purview_namespace'
  properties: {
    fqdns: []
    groupId: 'namespace'
    privateLinkResourceId: purviewManagedEventHubId
  }
}

resource datafactoryKeyVault001ManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: datafactoryManagedVirtualNetwork
  name: replace(keyVault001Name, '-', '')
  properties: {
    fqdns: []
    groupId: 'vault'
    privateLinkResourceId: keyVault001Id
  }
}

resource datafactoryKeyVault001LinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: replace(keyVault001Name, '-', '')
  dependsOn: [
    datafactoryKeyVault001ManagedPrivateEndpoint
  ]
  properties: {
    type: 'AzureKeyVault'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Key Vault for storing secrets'
    parameters: {}
    typeProperties: {
      baseUrl: 'https://${keyVault001Name}${environment().suffixes.keyvaultDns}/'
    }
  }
}

resource datafactorySqlServer001ManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: datafactoryManagedVirtualNetwork
  name: replace(sqlServer001Name, '-', '')
  properties: {
    fqdns: []
    groupId: 'sqlServer'
    privateLinkResourceId: sqlServer001Id
  }
}

resource datafactorySqlserver001LinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: '${replace(sqlServer001Name, '-', '')}${replace(sqlDatabase001Name, '-', '')}'
  dependsOn: [
    datafactorySqlServer001ManagedPrivateEndpoint
  ]
  properties: {
    type: 'AzureSqlDatabase'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Sql Database for storing metadata'
    parameters: {}
    typeProperties: {
      connectionString: 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlServer001Name}${environment().suffixes.sqlServerHostname};Initial Catalog=${sqlDatabase001Name}'
    }
  }
}

resource datafactoryStorageRawManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: datafactoryManagedVirtualNetwork
  name: storageRawName
  properties: {
    fqdns: []
    groupId: 'dfs'
    privateLinkResourceId: storageRawId
  }
}

resource datafactoryStorageRawLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: storageRawName
  dependsOn: [
    datafactoryStorageRawManagedPrivateEndpoint
  ]
  properties: {
    type: 'AzureBlobFS'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Storage Account for raw data'
    parameters: {}
    typeProperties: {
      url: 'https://${storageRawName}.dfs.${environment().suffixes.storage}'
    }
  }
}

resource datafactoryStorageEnrichedCuratedManagedPrivateEndpoint 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: datafactoryManagedVirtualNetwork
  name: storageEnrichedCuratedName
  properties: {
    fqdns: []
    groupId: 'dfs'
    privateLinkResourceId: storageEnrichedCuratedId
  }
}

resource datafactoryStorageEnrichedCuratedLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: storageEnrichedCuratedName
  dependsOn: [
    datafactoryStorageEnrichedCuratedManagedPrivateEndpoint
  ]
  properties: {
    type: 'AzureBlobFS'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Storage Account for raw data'
    parameters: {}
    typeProperties: {
      url: 'https://${storageEnrichedCuratedName}.dfs.${environment().suffixes.storage}'
    }
  }
}

resource datafactoryDatabricksLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: datafactory
  name: replace(databricks001Name, '-', '')
  properties: {
    type: 'AzureDatabricks'
    annotations: []
    connectVia: {
      type: 'IntegrationRuntimeReference'
      referenceName: datafactoryManagedIntegrationRuntime001.name
      parameters: {}
    }
    description: 'Azure Databricks Compute for Data Engineering'
    parameters: {
      DatabricksClusterType: {
        type: 'String'
        defaultValue: 'Standard_DS3_v2'
      }
      DatabricksAutoscale: {
        type: 'String'
        defaultValue: '1:15'
      }
      DatabrickClusterVersion: {
        type: 'String'
        defaultValue: '7.3.x-scala2.12'
      }
    }
    typeProperties: {
      authentication: 'MSI'
      domain: 'https://${databricks001WorkspaceUrl}'
      newClusterCustomTags: {
        costCenter: 'ABCDE-12345'
      }
      newClusterDriverNodeType: '@linkedService().DatabricksClusterType'
      newClusterNodeType: '@linkedService().DatabricksClusterType'
      newClusterNumOfWorker: '@linkedService().DatabricksAutoscale'
      newClusterSparkEnvVars: {
        PYSPARK_PYTHON: '/databricks/python3/bin/python3'
      }
      newClusterVersion: '@linkedService().DatabrickClusterVersion'
      // policyId: ''  // Uncomment to set the default cluster policy ID for jobs running on the Databricks workspace
      workspaceResourceId: databricks001Id
    }
  }
}

// Outputs
output datafactoryId string = datafactory.id
