[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $TenantId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientSecret,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksWorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksInstanceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksPatToken,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $NotificationEmail,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String[]]
    $GroupIdList
)

# Import Helper Functions
Write-Output "Importing Helper Functions"
. "$PSScriptRoot\Helper.ps1"

# Authentication and get AAD Token
Write-Output "Logging in and getting AAD Token"
Get-AadToken `
    -TenantId $TenantId `
    -ClientId $ClientId `
    -ClientSecret $ClientSecret

# Setup SCIM Enterprise Application
Write-Output "Setting up SCIM Enterprise Application"
New-ScimSetup `
    -DatabricksWorkspaceName $DatabricksWorkspaceName `
    -DatabricksInstanceName $DatabricksInstanceName `
    -DatabricksPatToken $DatabricksPatToken `
    -NotificationEmail $NotificationEmail `
    -GroupIdList $GroupIdList

# Completed Setup
Write-Output "Completed Setup"
