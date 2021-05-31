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
var storageExternal001PrivateEndpointNameBlob = '${storageExternal001.name}-blob-private-endpoint'

// Resources
module storageExternal001 'exernalstorage/storage.bicep' = {
  name: 'storageExternal001'
  scope: resourceGroup()
  params: {
    location: location
    prefix: prefix
    tags: tags
    subnetId: subnetId
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    numbering: '001'
  }
}

// Outputs
