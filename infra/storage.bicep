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

// Resources
module storageRaw 'datalake.bicep' = {
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

module storageEnrichedCurated 'datalake.bicep' = {
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

module storageWorkspace 'datalake.bicep' = {
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
