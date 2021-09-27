// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// This template is used to create a lock.
targetScope = 'resourceGroup'

// Parameters
@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param lockEffect string = 'CanNotDelete'

// Variables

// Resources
resource lock 'Microsoft.Authorization/locks@2016-09-01' = {
  name: 'lock'
  properties: {
    level: lockEffect
    notes: 'Prevent Deletion of Resource Group and resources within the Resource Group.'
  }
}

// Outputs
