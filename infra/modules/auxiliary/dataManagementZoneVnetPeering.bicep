// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// The module contains a template to create a vnet peering connection.
targetScope = 'resourceGroup'

// Parameters
param dataManagementZoneVnetId string
param dataLandingZoneVnetId string

// Variables
var dataManagementZoneVnetName = length(split(dataManagementZoneVnetId, '/')) >= 9 ? last(split(dataManagementZoneVnetId, '/')) : 'incorrectSegmentLength'
var dataLandingZoneVnetName = length(split(dataLandingZoneVnetId, '/')) >= 9 ? last(split(dataLandingZoneVnetId, '/')) : 'incorrectSegmentLength'

// Resources
resource dataManagementZoneDataLandingZoneVnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-11-01' = {
  name: '${dataManagementZoneVnetName}/${dataLandingZoneVnetName}'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    peeringState: 'Connected'
    remoteVirtualNetwork: {
      id: dataLandingZoneVnetId
    }
    useRemoteGateways: false
  }
}

// Outputs
