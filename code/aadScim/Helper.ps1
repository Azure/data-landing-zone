$accessToken = $null
$accessTokenExpiry = $null

function Get-AadToken {
    <#
    .SYNOPSIS
        Gets an AAD token for a registered AAD application. The application requires the following API permissions:
            * Application.ReadWrite.All
            * AppRoleAssignment.ReadWrite.All
            * Directory.ReadWrite.All
        Returns a list of services that are set to start automatically, are not
        currently running, excluding the services that are set to delayed start.

    .DESCRIPTION
        Get-MrAutoStoppedService is a function that returns a list of services from
        the specified remote computer(s) that are set to start automatically, are not
        currently running, and it excludes the services that are set to start automatically
        with a delayed startup.

    .PARAMETER TenantId
        Specifies the AAD tenant ID of the application.

    .PARAMETER ClientId
        Specifies the client ID of the application.

    .PARAMETER ClientSecret
        Specifies client secret of the application.

    .EXAMPLE
        Get-AadToken -TenantId '<your-tenant-id>' -ClientId '<your-client-id>' -ClientId '<your-client-secret>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to get AAD Token failed"
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
    <#
    .SYNOPSIS
        Checks whether authentication was executed successfully.

    .DESCRIPTION
        The function checks whether authentication was successfully executed.
        The AAD token must exist and must be valid and not expired.

    .EXAMPLE
        Assert-Authentication

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    param ()
    # Get Unix time
    Write-Verbose "Getting Unix time"
    $unixTime = (New-TimeSpan -Start (Get-Date "01/01/1970") -End (Get-Date -AsUTC)).TotalSeconds

    # Check authentication
    Write-Verbose "Checking authentication"
    if ([string]::IsNullOrEmpty($accessToken) -or [string]::IsNullOrEmpty($accessTokenExpiry)) {
        # Not authenticated
        Write-Verbose "Please authenticate before invoking Microsoft Graph REST APIs"
        throw "Not authenticated"
    }
    elseif (($accessTokenExpiry - $unixTime) -le 600) {
        # Access token expired
        Write-Verbose "Microsoft Access token expired"
        throw "Microsoft Access token expired"
    }
}


function New-DatabricksEnterpriseApplication {
    <#
    .SYNOPSIS
        Created a new Databricks Enterprise Application in AAD.

    .DESCRIPTION
        New-DatabricksEnterpriseApplication creates a new Databricks Enterprise Application based on the
        provided parameters.

    .PARAMETER DatabricksWorkspaceName
        Function expects the Databricks workspace name which is ussed for the name of the enterprise
        application taht gets created. Final name will be specified as '<your-workspace-name>-scim'.

    .EXAMPLE
        New-DatabricksEnterpriseApplication -DatabricksWorkspaceName '<your-databricks-workspace-name>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to register Databricks Enterprise Application failed"
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
    <#
    .SYNOPSIS
        Retrieves the template for the provisioning connector.

    .DESCRIPTION
        Applications in the gallery that are enabled for provisioning have templates to streamline configuration.
        This function retrieves the template for the provisioning configuration.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .EXAMPLE
        Get-SynchronisationTemplate -ObjectId '<your-service-principal-object-id>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to get synchronisation template failed"
        throw "REST API call failed"
    }
    return $response
}


function New-SynchronisationJob {
    <#
    .SYNOPSIS
        Creates a new synchronisation job for the Databricks enterprise application in AADs.

    .DESCRIPTION
        New-SynchronisationJob creates a new synchronisation job for the Databricks enterprise application.
        This job is required for all subsequent steps.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .EXAMPLE
        New-SynchronisationJob -ObjectId '<your-service-principal-object-id>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to create new synchronisation job failed"
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


function Test-DatabricksConnection {
    <#
    .SYNOPSIS
        Test the connection between the Databricks workspace and the application.

    .DESCRIPTION
        Test-DatabricksConnection tests whether the connection between Databricks and the enterprise application can
        be successfully established with the provided parameters.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER JobId
        Function expects a Databricks enterprise application service principal synchronisation job id
        which is returned by New-SynchronisationJob.

    .PARAMETER DatabricksInstanceName
        Function expects the Databricks instance name. More details on this can be found here:
        https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#per-workspace-url

    .PARAMETER DatabricksPatToken
        Function expects a Databricks PAT token from the workspace.

    .EXAMPLE
        Test-DatabricksConnection -ObjectId '<your-service-principal-object-id>' -JobId '<your-synchronisation-job-id>' -DatabricksInstanceName '<your-databricks-instance-name>' -DatabricksPatToken '<your-databricks-pat-token>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        $DatabricksInstanceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DatabricksPatToken
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
        'templateId'          = 'dataBricks'
        'useSavedCredentials' = 'false'
        'credentials'         = @(
            @{
                'key'   = 'BaseAddress'
                'value' = "https://${DatabricksInstanceName}/api/2.0/preview/scim"
            },
            @{
                'key'   = 'SecretToken'
                'value' = "${DatabricksPatToken}"
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
        Write-Error "REST API to test connection failed"
        throw "REST API call failed"
    }
    return $response
}


function Save-ProvisioningCredentials {
    <#
    .SYNOPSIS
        Saves the credentials for the Databricks enterprise application.

    .DESCRIPTION
        Saves the credentials for the Databricks enterprise application in order to allow authorization access.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER JobId
        Function expects a Databricks enterprise application service principal synchronisation job id
        which is returned by New-SynchronisationJob.

    .PARAMETER DatabricksInstanceName
        Function expects the Databricks instance name. More details on this can be found here:
        https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#per-workspace-url

    .PARAMETER DatabricksPatToken
        Function expects a Databricks PAT token from the workspace.

    .PARAMETER NotificationEmail
        Function expects a notification email address to which messages are sent, if there are synchronization issues.

    .EXAMPLE
        Save-ProvisioningCredentials -ObjectId '<your-service-principal-object-id>' -JobId '<your-synchronisation-job-id>' -DatabricksInstanceName '<your-databricks-instance-name>' -DatabricksPatToken '<your-databricks-pat-token>' -NotificationEmail '<your-notification-email>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
                'value' = "{`"Enabled`":true,`"Recipients`":`"${NotificationEmail}`"}"
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
        Write-Error "REST API to save provisioning credentials failed"
        throw "REST API call failed"
    }
    return $response
}


function New-GroupAssignment {
    <#
    .SYNOPSIS
        Assigns an AAD group to the Databricks enterprise application.

    .DESCRIPTION
        Assigns an AAD group to the Databricks enterprise application which gets then synched to the
        Databricks workspace.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER GroupId
        Function expects a group object id which is granted access to the Databricks workspace via SCIM.

    .EXAMPLE
        New-GroupAssignment -ObjectId '<your-service-principal-object-id>' -GroupId '<your-group-id>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to create new group assignment failed"
        throw "REST API call failed"
    }
    return $response
}


function Start-SynchronisationJob {
    <#
    .SYNOPSIS
        Starts the synchronisation between the enterprise application and the Databricks workspace.

    .DESCRIPTION
        Synchronizes the users between the Databricks workspace and the enterprise application.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER JobId
        Function expects a Databricks enterprise application service principal synchronisation job id
        which is returned by New-SynchronisationJob.

    .EXAMPLE
        Start-SynchronisationJob -ObjectId '<your-service-principal-object-id>' -GroupId '<your-group-id>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        'Method'      = 'Post'
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
        Write-Error "REST API to start synchronisation job failed"
        throw "REST API call failed"
    }
    return $response
}


function Get-ProvisioningAuditLogs {
    <#
    .SYNOPSIS
        Monitors the provisioning job status.

    .DESCRIPTION
        Get-ProvisioningAuditLogs can be used to track the progress of the current provisioning job
        cycle as well as statistics to date such as the number of users and groups that have been
        created in the Databricks workspace.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER JobId
        Function expects a Databricks enterprise application service principal synchronisation job id
        which is returned by New-SynchronisationJob.

    .EXAMPLE
        Get-ProvisioningAuditLogs -ObjectId '<your-service-principal-object-id>' -JobId '<your-job-id>'

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
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
        Write-Error "REST API to get provisioning logs failed"
        throw "REST API call failed"
    }
    return $response
}


function New-ScimSetup {
    <#
    .SYNOPSIS
        Creates the end-to-end SCIM synch setup for a Databricks workspace.

    .DESCRIPTION
        This function executes all required steps end-to-end to create a Databricks SCIM enterprise application.

    .PARAMETER DatabricksWorkspaceName
        Function expects the Databricks workspace name which is ussed for the name of the enterprise
        application taht gets created. Final name will be specified as '<your-workspace-name>-scim'.

    .PARAMETER DatabricksInstanceName
        Function expects the Databricks instance name. More details on this can be found here:
        https://docs.microsoft.com/en-us/azure/databricks/workspace/workspace-details#per-workspace-url

    .PARAMETER DatabricksPatToken
        Function expects a Databricks PAT token from the workspace.

    .PARAMETER NotificationEmail
        Function expects a notification email address to which messages are sent, if there are synchronization issues.

    .PARAMETER GroupIdList
        Function expects a list of group object ids which is granted access to the Databricks workspace via SCIM.

    .EXAMPLE
        New-ScimSetup -DatabricksWorkspaceName '<your-databricks-workspace-name>' -DatabricksInstanceName '<your-databricks-instance-name>' -DatabricksPatToken '<your-databricks-pat-token>' -NotificationEmail '<your-notification-email>' -GroupIdList @('<your-group-id-1>', '<your-group-id-2>')

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    [OutputType("System.Object[]")]
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

        [Parameter(Mandatory = $false)]
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

    # Sleep for 5 Seconds
    Write-Verbose "Sleeping for 5 seconds"
    Start-Sleep -Seconds 5

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
    Test-DatabricksConnection `
        -ObjectId $objectId `
        -JobId $jobId `
        -DatabricksInstanceName $DatabricksInstanceName `
        -DatabricksPatToken $DatabricksPatToken

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
            -ObjectId $objectId `
            -GroupId $groupId
    }

    # Start Synchronisation Job
    Write-Verbose "Starting Synchronisation Job"
    Start-SynchronisationJob `
        -ObjectId $objectId `
        -JobId $jobId

    # Get Provisioning Logs
    Write-Output "Getting Provisioning Logs"
    $provisioningLogs = Get-ProvisioningAuditLogs `
        -ObjectId $objectId `
        -JobId $jobId

    Write-Output "Provisioning Logs: ${provisioningLogs}"

    return $objectId, $jobId
}

function New-GroupListAssignment {
    <#
    .SYNOPSIS
        Assigns AAD groups to the enterprise application to give them access to the Databricks workspace.

    .DESCRIPTION
        This function executes all required steps end-to-end to assign AAD groups to the enterprise
        application and starts a synch job with the Databricks workspace.

    .PARAMETER ObjectId
        Function expects the Databricks enterprise application service principal object id which is
        returned by New-DatabricksEnterpriseApplication.

    .PARAMETER JobId
        Function expects a Databricks enterprise application service principal synchronisation job id
        which is returned by New-SynchronisationJob.

    .PARAMETER GroupIdList
        Function expects a list of group object ids which is granted access to the Databricks workspace via SCIM.

    .EXAMPLE
        New-GroupListAssignment -ObjectId '<your-service-principal-object-id>' -JobId '<your-job-id>' -GroupIdList @('<your-group-id-1>', '<your-group-id-2>')

    .NOTES
        Author:  Marvin Buss
        GitHub:  @marvinbuss
    #>
    [CmdletBinding()]
    [OutputType("System.Object[]")]
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
            -GroupId $groupId
    }

    # Start Synchronisation Job
    Write-Verbose "Starting Synchronisation Job"
    Start-SynchronisationJob `
        -ObjectId $objectId `
        -JobId $jobId

    return $objectId, $jobId
}
