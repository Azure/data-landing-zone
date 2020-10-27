<#
.SYNOPSIS
Gets an access token from Azure Active Directory

.DESCRIPTION
Gets an access token from Azure Active Directory that can be used to authenticate to for example Microsoft Graph or Azure Resource Manager.

Run without parameters to get an access token to Microsoft Graph and the users original tenant.

Use the parameter -Interactive and the script will open the sign in experience in the default browser without user having to copy any code.

.PARAMETER ClientID
Application client ID, defaults to well-known ID for Microsoft Azure PowerShell

.PARAMETER TenantID
ID of tenant to sign in to, defaults to the tenant where the user was created

.PARAMETER Scopes
Identifier for target scopes, this is where the token will be valid. Details@ https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-permissions-and-consent
Format: "https://graph.microsoft.com/Application.ReadWrite.All https://graph.microsoft.com/Directory.AccessAsUser.All https://graph.microsoft.com/Directory.ReadWrite.All"

.EXAMPLE
$Token = Connect-AzureDevicelogin -Scopes $Scopes -ClientID $ClientID -TenantID $TenantID
$Headers = @{'Authorization' = "Bearer $Token" }
$UsersUri = 'https://graph.microsoft.com/v1.0/users?$top=5'
$Users = Invoke-RestMethod -Method GET -Uri $UsersUri -Headers $Headers
$Users.value.userprincipalname

Using Microsoft Graph to print the userprincipalname of 5 users in the tenant.

.NOTES
# Adapted from https://blog.simonw.se/getting-an-access-token-for-azuread-using-powershell-and-device-login-flow/
# Additional info https://github.com/Azure-Samples/active-directory-dotnetcore-devicecodeflow-v2#register-the-client-app-active-directory-dotnet-deviceprofile
# IMPORTANT! Enable allowPublicClient  in the app registration manifest otherwise you may encounter AADSTS7000218: The request body must contain the following parameter: 'client_assertion' or 'client_secret' 
# https://docs.microsoft.com/en-us/azure/active-directory/develop/reference-app-manifest#allowpublicclient-attribute
#>
function Connect-AzureDevicelogin {
    [cmdletbinding()]
    param( 
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ClientID,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $TenantID,
        
        [Parameter()]
        $Scopes = "https://graph.microsoft.com/*",
        
        # Timeout in seconds to wait for user to complete sign in process
        [Parameter(DontShow)]
        $Timeout = 300
    )
    try {
        Write-Host "$CLientID -- $TenantID -- $Scopes"

        $DeviceCodeRequestParams = @{
            Method = 'POST'
            Uri    = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/devicecode"
            Body   = @{
                scope  = $Scopes
                client_id = $ClientId
            }
        }
        $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams

        Write-Host $DeviceCodeRequest.message -ForegroundColor Yellow

        $TokenRequestParams = @{
            Method = 'POST'
            Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
            Body   = @{
                grant_type = "urn:ietf:params:oauth:grant-type:device_code"
                code       = $DeviceCodeRequest.device_code
                client_id  = $ClientId
            }
        }
        $TokenRequest = $null
        $TimeoutTimer = [System.Diagnostics.Stopwatch]::StartNew()
        while ([string]::IsNullOrEmpty($TokenRequest.access_token)) {
            if ($TimeoutTimer.Elapsed.TotalSeconds -gt $Timeout) {
                throw 'Login timed out, please try again.'
            }
            $TokenRequest = try {
                Invoke-RestMethod @TokenRequestParams -ErrorAction Stop
            }
            catch {
                $Message = $_.ErrorDetails.Message | ConvertFrom-Json
                if ($Message.error -ne "authorization_pending") {
                    throw
                }
            }
            Start-Sleep -Seconds 1
        }
        Write-Output $TokenRequest.access_token
        return $TokenRequest
    }
    finally {
        try {
            $TimeoutTimer.Stop()
        }
        catch {
            Write-Error $_.Exception.Message
        }
    }
}