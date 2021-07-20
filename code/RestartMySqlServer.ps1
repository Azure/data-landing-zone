# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $MySqlServerName
)

# Install Required Module
Write-Output "Installing Required Module"
Set-PSRepository `
    -Name PSGallery `
    -InstallationPolicy Trusted
Install-Module `
    -Name Az.MySql `
    -Repository PSGallery `
    -Force

# Restart MySql Server
Write-Output "Restarting MySql Server"
Restart-AzMySqlServer `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -Name $MySqlServerName
