// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdDfs string
param privateDnsZoneIdBlob string

// Variables
var domainFileSytemNames = [
  'data'
  'dd001'
  'dd002'
]
var dataProductFileSystemNames = [
  'data'
  'dp001'
  'dp002'
]
var storageRawPrivateEndpointNameBlob = '${storageRaw.name}-blob-private-endpoint'
var storageRawPrivateEndpointNameDfs = '${storageRaw.name}-dfs-private-endpoint'
var storageEnrichedCuratedPrivateEndpointNameBlob = '${storageEnrichedCurated.name}-blob-private-endpoint'
var storageEnrichedCuratedPrivateEndpointNameDfs = '${storageEnrichedCurated.name}-dfs-private-endpoint'
var storageWorkspacePrivateEndpointNameBlob = '${storageWorkspace.name}-blob-private-endpoint'
var storageWorkspacePrivateEndpointNameDfs = '${storageWorkspace.name}-dfs-private-endpoint'

// Resources
module storageRaw 'storage/storage.bicep' = {
  name: 'storageRaw'
  scope: resourceGroup()
  params: {
    location: location
    prefix: prefix
    tags: tags
    subnetId: subnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: domainFileSytemNames
    layer: 'raw'
  }
}

module storageEnrichedCurated 'storage/storage.bicep' = {
  name: 'storageEnrichedCurated'
  scope: resourceGroup()
  params: {
    location: location
    prefix: prefix
    tags: tags
    subnetId: subnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: domainFileSytemNames
    layer: 'encur'
  }
}

module storageWorkspace 'storage/storage.bicep' = {
  name: 'storageWorkspace'
  scope: resourceGroup()
  params: {
    location: location
    prefix: prefix
    tags: tags
    subnetId: subnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: dataProductFileSystemNames
    layer: 'work'
  }
}

// Outputs
