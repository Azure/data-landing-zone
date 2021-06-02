// This template is used as a module from the network.bicep template. 
// The module contains a template to create vnet peering from the data management zone vnet.
targetScope = 'resourceGroup'

// Parameters
param dataManagementZoneVnetId string
param dataLandingZoneVnetId string

// Variables
var dataManagementZoneVnetName = last(split(dataManagementZoneVnetId, '/'))
var dataLandingZoneVnetName = last(split(dataLandingZoneVnetId, '/'))

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
