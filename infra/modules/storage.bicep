// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create storage resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdDfs string = ''
param privateDnsZoneIdBlob string = ''

// Variables
var storageRawName = '${prefix}-raw'
var storageEnrichedCuratedName = '${prefix}-encur'
var storageWorkspaceName = '${prefix}-work'
var domainFileSytemNames = [
  'data'
  'di001'
  'di002'
]
var dataProductFileSystemNames = [
  'data'
  'dp001'
  'dp002'
]

// Resources
module storageRaw 'services/storage.bicep' = {
  name: 'storageRaw'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    storageName: storageRawName
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: domainFileSytemNames
  }
}

module storageEnrichedCurated 'services/storage.bicep' = {
  name: 'storageEnrichedCurated'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    storageName: storageEnrichedCuratedName
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: domainFileSytemNames
  }
}

module storageWorkspace 'services/storage.bicep' = {
  name: 'storageWorkspace'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    storageName: storageWorkspaceName
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    privateDnsZoneIdDfs: privateDnsZoneIdDfs
    fileSystemNames: dataProductFileSystemNames
  }
}

// Outputs
output storageRawId string = storageRaw.outputs.storageId
output storageRawFileSystemId string = storageRaw.outputs.storageFileSystemIds[0].storageFileSystemId
output storageEnrichedCuratedId string = storageEnrichedCurated.outputs.storageId
output storageEnrichedCuratedFileSystemId string = storageEnrichedCurated.outputs.storageFileSystemIds[0].storageFileSystemId
output storageWorkspaceId string = storageWorkspace.outputs.storageId
output storageWorkspaceFileSystemId string = storageWorkspace.outputs.storageFileSystemIds[0].storageFileSystemId
