// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used as a module from the main.bicep template. 
// The module contains a template to create external storage resources.
targetScope = 'resourceGroup'

// Parameters
param location string
param prefix string
param tags object
param subnetId string
param privateDnsZoneIdBlob string = ''

// Variables
var storageExternal001Name = '${prefix}-ext001'
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
    storageName: storageExternal001Name
    privateDnsZoneIdBlob: privateDnsZoneIdBlob
    fileSytemNames: fileSytemNames
  }
}

// Outputs
