// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
@secure()
param administratorPassword string
param subnetId string
param datafactoryPrivateDnsZoneIdDataFactory string
param datafactoryPrivateDnsZoneIdPortal string

// Variables
var vmss001Name = '${prefix}-shir001'
var datafactoryPrivateEndpointNameDatafactory = '${datafactory.name}-datafactory-private-endpoint'
var datafactoryPrivateEndpointNamePortal = '${datafactory.name}-portal-private-endpoint'

// Resources
resource artifactstorage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: replace('${prefix}artifactstorage', '-', '')
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
      resourceAccessRules: []
    }
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
    }
    supportsHttpsTrafficOnly: true
  }
}

resource scriptsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  name: '${artifactstorage.name}/default/scripts'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: '${prefix}-integration-datafactory'
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Disabled'
  }
}

resource datafactoryIntegrationRuntime001 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${datafactory.name}/dataLandingZoneSelfHostedIntegrationRuntime${vmss001Name}'
  properties: {
    type: 'SelfHosted'
    description: 'Data Landing Zone - Self Hosted Integration Runtime running on ${vmss001Name}'
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

resource datafactoryPrivateEndpointDatafactoryARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${datafactoryPrivateEndpointDatafactory.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointDatafactory.name}-arecord'
        properties: {
          privateDnsZoneId: datafactoryPrivateDnsZoneIdDataFactory
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

resource datafactoryPrivateEndpointPortalARecord 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${datafactoryPrivateEndpointPortal.name}/aRecord'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${datafactoryPrivateEndpointPortal.name}-arecord'
        properties: {
          privateDnsZoneId: datafactoryPrivateDnsZoneIdPortal
        }
      }
    ]
  }
}

module datafactorySelfHostedIntegrationRuntime001 'integration/shir.bicep' = {
  name: 'datafactorySelfHostedIntegrationRuntime001'
  scope: resourceGroup()
  params: {
    administratorPassword: administratorPassword
    datafactoryIntegrationRuntimeAuthKey: listAuthKeys(datafactoryIntegrationRuntime001.id, datafactoryIntegrationRuntime001.apiVersion).authKey1
    location: location
    prefix: prefix
    storageAccountContainerName: scriptsContainer.name
    storageAccountId: artifactstorage.id
    subnetId: subnetId
    tags: tags
    vmssName: '${prefix}-shir001'
    vmssSkuCapacity: 1
    vmssSkuName: 'Standard_DS2_v2'
    vmssSkuTier: 'Standard'
  }
}

// Outputs
