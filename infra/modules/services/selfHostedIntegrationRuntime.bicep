// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a Self-hosted Integration Runtime.
targetScope = 'resourceGroup'

// Parameters
param location string
param tags object
param subnetId string
param vmssName string
param vmssSkuName string = 'Standard_DS2_v2'
param vmssSkuTier string = 'Standard'
param vmssSkuCapacity int = 1
param storageAccountId string
param storageAccountContainerName string
param administratorUsername string = 'VmssMainUser'
@secure()
param administratorPassword string
@secure()
param datafactoryIntegrationRuntimeAuthKey string
param portalDeployment bool = false

// Variables
var storageAccountName = length(split(storageAccountId, '/')) >= 9 ? last(split(storageAccountId, '/')) : 'incorrectSegmentLength'
var loadbalancerName = '${vmssName}-lb'
var fileUri = 'https://raw.githubusercontent.com/Azure/data-landing-zone/main/code/installSHIRGateway.ps1'

// Resources
resource loadbalancer001 'Microsoft.Network/loadBalancers@2020-11-01' = {
  name: loadbalancerName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    backendAddressPools: [
      {
        name: '${vmssName}-backendaddresspool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendipconfiguration'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    inboundNatPools: [
      {
        name: '${vmssName}-natpool'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, 'frontendipconfiguration')
          }
          protocol: 'Tcp'
          frontendPortRangeStart: 50000
          frontendPortRangeEnd: 50099
          backendPort: 3389
          idleTimeoutInMinutes: 4
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'proberule'
        properties: {
          loadDistribution: 'Default'
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, '${vmssName}-backendaddresspool')
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadbalancerName, 'frontendipconfiguration')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', loadbalancerName, '${vmssName}-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
    ]
    probes: [
      {
        name: '${vmssName}-probe'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}

resource vmss001 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: vmssName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: vmssSkuName
    tier: vmssSkuTier
    capacity: vmssSkuCapacity
  }
  properties: {
    additionalCapabilities: {}
    automaticRepairsPolicy: {}
    doNotRunExtensionsOnOverprovisionedVMs: true
    overprovision: true
    platformFaultDomainCount: 1
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      priority: 'Regular'
      osProfile: {
        adminUsername: administratorUsername
        adminPassword: administratorPassword
        computerNamePrefix: take(vmssName, 9)
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              dnsSettings: {}
              enableAcceleratedNetworking: false
              enableFpga: false
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: '${vmssName}-ipconfig'
                  properties: {
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadbalancerName, '${vmssName}-backendaddresspool')
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadbalancerName, '${vmssName}-natpool')
                      }
                    ]
                    primary: true
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: subnetId
                    }
                  }
                }
              ]
            }
          }
        ]
      }
      storageProfile: {
        imageReference: {
          offer: 'WindowsServer'
          publisher: 'MicrosoftWindowsServer'
          sku: '2019-Datacenter'
          version: 'latest'
        }
        osDisk: {
          caching: 'ReadWrite'
          createOption: 'FromImage'
        }
      }
      extensionProfile: {
        extensions: [
          {
            name: '${vmssName}-integrationruntime-shir'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  portalDeployment ? fileUri : 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${storageAccountContainerName}/installSHIRGateway.ps1'
                ]
              }
              protectedSettings: {
                commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File installSHIRGateway.ps1 -gatewayKey "${datafactoryIntegrationRuntimeAuthKey}"'
                storageAccountName: storageAccountName
                storageAccountKey: listkeys(storageAccountId, '2021-02-01').keys[0].value
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
