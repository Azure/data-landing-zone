// This template is used as a module from the main.bicep template. 
// The module contains a template to create network resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdBlob string

// Variables
var fileSytemNames = [
  'data'
]

// Resources
module storageExternal001 'services/externalstorage.bicep' = {
  name: 'storageExternal001'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    subnetId: subnetId
    storageName: '${prefix}-ext001'
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    fileSytemNames: fileSytemNames
  }
}

// Outputs
