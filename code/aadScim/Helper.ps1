$Global:accessToken = $null
$Global:accessTokenExpiry = $null

function Get-AadToken {
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
        $ClientSecret
    )
    # Set Authority Host URL
    Write-Verbose "Setting Authority Host URL"
    $authorityHostUrl = "https://login.microsoftonline.com/${TenantId}/oauth2/v2.0/token"

    # Set body for REST call
    Write-Verbose "Setting Body for REST API call"
    $body = @{
        'tenantId'      = $TenantId
        'client_id'     = $ClientId
        'client_secret' = $ClientSecret
        'scope'         = 'https://graph.microsoft.com/.default'
        'grant_type'    = 'client_credentials'
    }

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $authorityHostUrl
        'Method'      = 'Post'
        'Body'        = $body
        'ContentType' = 'application/x-www-form-urlencoded'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }

    # Calculate Access Token Expiry
    $unixTime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date -AsUTC)).TotalSeconds
    $accessTokenExpiry = $unixTime + $response.expires_in

    # Set global variables
    Write-Verbose "Setting global variables"
    Set-Variable -Name "accessToken" -Value $response.access_token -Scope global
    Set-Variable -Name "accessTokenExpiry" -Value $accessTokenExpiry -Scope global

    Write-Verbose "Access Token: ${Global:accessToken}"
    Write-Verbose "Access Token Expiry: ${Global:accessTokenExpiry}"
}


function Assert-Authentication {
    [CmdletBinding()]
    param ()
    # Get Unix time
    Write-Verbose "Getting Unix time"
    $unixTime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date -AsUTC)).TotalSeconds

    # Check authentication
    Write-Verbose "Checking authentication"
    if ([string]::IsNullOrEmpty($Global:accessToken) -or [string]::IsNullOrEmpty($Global:accessTokenExpiry)) {
        # Not authenticated
        Write-Verbose "Please authenticate before invoking Microsoft Graph REST APIs"
        throw "Not authenticated"
        
    }
    elseif (($Global:accessTokenExpiry - $unixTime) -le 600) {
        # Access token expired
        Write-Verbose "Microsoft Access token expired"
        throw "Microsoft Access token expired"
    }
}


function New-DatabricksEnterpriseApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DatabricksWorkspaceName,

        [Parameter(DontShow)]
        [String]
        $ApplicationTemplate = "9c9818d2-2900-49e8-8ba4-22688be7c675"
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/applicationTemplates/${ApplicationTemplate}/instantiate"
    Write-Verbose $graphApiUri

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    Write-Verbose $headers.values

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'displayName' = "${DatabricksWorkspaceName}-scim"
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Post'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }

    # Check response
    Write-Verbose "Checking response"
    $objectId = $response.servicePrincipal.objectId
    Write-Verbose "SP ID: ${objectId}"
    if (!$objectId) { 
        Write-Verbose "Instantiation service principal object id is null" 
        throw "Instantiation service principal object id is null" 
    }
    return $objectId
}


function Get-SynchronisationTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/templates"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }
    
    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Get'
        'Headers'     = $headers
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function New-SynchronisationJob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/jobs"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'templateId' = 'dataBricks'
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Post'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }

    # Check response
    Write-Verbose "Checking response"
    $jobId = $response.id
    if (!$jobId) {
        Write-Verbose "Synchronisation job id is null" 
        throw "Synchronisation job id is null" 
    }
    return $jobId
}


function Test-Connection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $JobId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DatabricksInstanceName
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/jobs/${JobId}/validateCredentials"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        # 'templateId'          = 'dataBricks'
        'useSavedCredentials' = 'false'
        'credentials'         = @(
            @{
                'key'   = 'BaseAddress'
                'value' = "https://${DatabricksInstanceName}/api/2.0/preview/scim"
            },
            @{
                'key'   = 'SecretToken'
                'value' = "${Global:accessToken}"
            }
        )
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Post'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function Save-ProvisioningCredentials {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

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
        $NotificationEmail
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/secrets"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'value' = @(
            @{
                'key'   = 'BaseAddress'
                'value' = "https://${DatabricksInstanceName}/api/2.0/preview/scim"
            },
            @{
                'key'   = 'SecretToken'
                'value' = "${DatabricksPatToken}"
            },
            @{
                'key'   = 'SyncNotificationSettings'
                'value' = @{
                    'Enabled'    = 'true'
                    'Recipients' = "${NotificationEmail}"
                }
            },
            @{
                'key'   = 'SyncAll'
                'value' = 'false'
            }
        )
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Put'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function New-GroupAssignment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupId
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/groups/${GroupId}/appRoleAssignments"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Set body for REST call
    Write-Verbose "Setting body for REST call"
    $body = @{
        'principalId' = "${GroupId}"
        'resourceId'  = "${ObjectId}"
        'appRoleId'   = 'a34c49f1-a169-404b-a890-00b3bfdbc1d6'
    } | ConvertTo-Json

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Post'
        'Headers'     = $headers
        'Body'        = $body
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function Start-SynchronisationJob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $JobId
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/jobs/${JobId}/start"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Put'
        'Headers'     = $headers
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function Get-ProvisioningAuditLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $JobId
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Set Graph API URI
    Write-Verbose "Setting Graph API URI"
    $graphApiUri = "https://graph.microsoft.com/beta/servicePrincipals/${ObjectId}/synchronization/jobs/${JobId}/"

    # Set header for REST call
    Write-Verbose "Setting header for REST call"
    $headers = @{
        'Content-Type'  = 'application/json'
        'Authorization' = "Bearer ${Global:accessToken}"
    }

    # Define parameters for REST method
    Write-Verbose "Defining parameters for pscore method"
    $parameters = @{
        'Uri'         = $graphApiUri
        'Method'      = 'Get'
        'Headers'     = $headers
        'ContentType' = 'application/json'
    }

    # Invoke REST API
    Write-Verbose "Invoking REST API"
    try {
        $response = Invoke-RestMethod @parameters
        Write-Verbose "Response: ${response}"
    }
    catch {
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        throw "REST API call failed"
    }
    return $response
}


function New-ScimSetup {
    [CmdletBinding()]
    param (
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $GroupIdList
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication

    # Instantiate Databricks Enterprise Application
    Write-Verbose "Instantiating Databricks Enterprise Application"
    $objectId = New-DatabricksEnterpriseApplication `
        -DatabricksWorkspaceName $databricksWorkspaceName
    
    # Get Synchronization Template
    Write-Verbose "Getting Synchronization Template"
    Get-SynchronisationTemplate `
        -ObjectId $objectId
    
    # Create Synchronization Job
    Write-Verbose "Creating Synchronization Job"
    $jobId = New-SynchronisationJob `
        -ObjectId $objectId
    
    # Test Connection to Databricks Workspace
    Write-Verbose "Testing Connection to Databricks Workspace"
    Test-Connection `
        -ObjectId $objectId `
        -JobId $jobId `
        -DatabricksInstanceName $DatabricksInstanceName
    
    # Save Provisioning Credentials for Enterprise Application
    Write-Verbose "Saving Provisioning Credentials for Enterprise Application"
    Save-ProvisioningCredentials `
        -ObjectId $objectId `
        -DatabricksInstanceName $DatabricksInstanceName `
        -DatabricksPatToken $DatabricksPatToken `
        -NotificationEmail $NotificationEmail
    
    # Add Group Assignment
    Write-Verbose "Adding Group Assignment"
    foreach ($groupId in $GroupIdList) {
        New-GroupAssignment `
            -ObjectId $ObjectId `
            -GroupId $groupId
    }
    
    # Start Synchronisation Job
    Write-Verbose "Starting Synchronisation Job"
    Start-SynchronisationJob `
        -ObjectId $objectId `
        -JobId $jobId
    
    return $objectId, $jobId
}

function New-GroupAssignment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ObjectId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $JobId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $GroupIdList
    )
    # Validate authentication
    Write-Verbose "Validating authentication"
    Assert-Authentication
    
    # Add Group Assignment
    Write-Verbose "Adding Group Assignment"
    foreach ($groupId in $GroupIdList) {
        New-GroupAssignment `
            -ObjectId $ObjectId `
            -GroupId $GroupId
    }
    
    # Start Synchronisation Job
    Write-Verbose "Starting Synchronisation Job"
    Start-SynchronisationJob `
        -ObjectId $objectId `
        -JobId $jobId
    
    return $objectId, $jobId
}
