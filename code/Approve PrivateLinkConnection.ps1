# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $ResourceId
)

# Get Private Link Endpoint Connection
Write-Host "Getting Private Link Endpoint Connection"
$privateEndpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $ResourceId
$privateEndpoints

# Approve all Private Link Endpoint Connection
Write-Host "Approving all Private Link Endpoint Connections"
foreach ($privateEndpoint in $privateEndpoints) {
	$id = $privateEndpoint.id
	Approve-AzPrivateEndpointConnection -ResourceId "${id}"
}
