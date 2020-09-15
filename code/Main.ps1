# Define script arguments
param (
    [Parameter(Mandatory = $true)]
    [String]
    $VaultName,

    [Parameter(Mandatory = $true)]
    [String]
    $SecretName,

    [Parameter(Mandatory=$false)]
    [Switch]
    $Force
)

# Get secret from key vault
Write-Output "Getting secret from key vault"
$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName

if (($Null -eq $Secret) -or ($Force)) {
    Write-Output "Secret does not exist yet. Creating new secret with name $SecretName."

    # Generate password
    Write-Output "Generating password"
    $Password = New-Password

    # Create secret in key vault
    Write-Output "Creating secret in key vault"
    Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $Password
}
else {
    Write-Output "Secret already exists. No need to create a new secret with name $SecretName."
}
