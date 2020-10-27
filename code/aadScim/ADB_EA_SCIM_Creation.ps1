Import-module .\Connect-AzureDevicelogin.ps1 -Force

$ClientID = 'fb53ccd3-730e-483e-b64a-3f9a91631017'
$TenantID = 'af26513a-fe59-4005-967d-bd744f659830' #common
$Scopes = "https://graph.microsoft.com/Application.ReadWrite.All https://graph.microsoft.com/Directory.AccessAsUser.All https://graph.microsoft.com/Directory.ReadWrite.All"

## EA ADB template
$ApplicationTemplate = "9c9818d2-2900-49e8-8ba4-22688be7c675"
$AdbEaName = "ADB Instance 100"
$databricksInstance = "adb-3469363868528983.3.azuredatabricks.net"
$PatToken = "{PAT TOKEN HERE}"

## AAD groups to add to workspace
$groupList = @('hr3','hr1','xxhr_10')

## Get bearer token for API calls
$TokenRequest = Connect-AzureDevicelogin -Scopes $Scopes -ClientID $ClientID -TenantID $TenantID
$Token = $TokenRequest.access_token

## Check group IDs exist
if(($groupList.count -gt 0) -and ($null -ne $groupList))
{
    ## Get group details via single call
    # create odata filter string, format: $filter=DisplayName+eq+'hr3'+or+DisplayName+eq+'hr1'
    $filterString = "`$filter="
    foreach ($group in $groupList) {
        $filterString += "DisplayName+eq+`'$group`'+or+"
    }
    # replace last +or+
    $filterString = $filterString -replace "(.*)\+or\+(.*)",'$1$2'
    
    $GetAADGroupParams = @{
        Method = 'GET'
        Uri    = "https://graph.microsoft.com/v1.0/groups?$filterString"
        Headers = @{
            'Content-Type' = 'application/json'
            'Authorization' = "Bearer $Token"
        }
    }
    $GetAADGroup = try { Invoke-RestMethod @GetAADGroupParams -ErrorAction Stop }
    catch { # if response not 200
        Write-Host -ForegroundColor:Red $_
        Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
        Write-Host -ForegroundColor:Red $_.Exception.Message
        return -1
    }

    # Extract list of ids
    $groupIdList = $GetAADGroup.value | Select id
    ## Count mismatch logic?
}
else{
    Write-Host -ForegroundColor:Yellow "No groups provided"
}

## https://docs.microsoft.com/en-us/graph/application-provisioning-configure-api?tabs=http#step-1-create-the-gallery-application
################################################ 
## Step 1/5
## INSTANTIATE a new application from gallery
$InstantiateRequestParams = @{
    Method = 'POST'
    Uri    = "https://graph.microsoft.com/beta/applicationTemplates/$ApplicationTemplate/instantiate"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
    Body = @{
        'displayName' = $AdbEaName
    } | ConvertTo-Json
}
$InstantiateRequest = try {
    Invoke-RestMethod @InstantiateRequestParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}

$objectId = $InstantiateRequest.servicePrincipal.objectId
if (!$objectId) { 
    Write-Host -ForegroundColor:Red "Instantiation service principal objectid is null" 
    return -1
}

################################################
## Get the synchronisation template
$SynchronisationTemplateParams = @{
    Method = 'GET'
    Uri    = "https://graph.microsoft.com/beta/servicePrincipals/$objectId/synchronization/templates"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
}
$SynchronisationTemplateRequest = try {
    Invoke-RestMethod @SynchronisationTemplateParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}

################################################
## Step 2/5
## Create the synchronisation job based on template
## templateId from GET https://graph.microsoft.com/beta/servicePrincipals/{id}/synchronization/templates
$SynchronisationJobParams = @{
    Method = 'POST'
    Uri    = "https://graph.microsoft.com/beta/servicePrincipals/$objectId/synchronization/jobs"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
    Body = @{
        'templateId' = 'dataBricks'
    } | ConvertTo-Json
}
$SynchronisationJobRequest = try {
    Invoke-RestMethod @SynchronisationJobParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}

$jobId = $SynchronisationJobRequest.id
if (!$jobId) { 
    Write-Host -ForegroundColor:Red "Synchronisation jobid is null" 
    return -1
}

################################################
## Step 3/5
## Authorise access - Test connection
$SynchronisationJobValidationParams = @{
    Method = 'POST'
    Uri    = "https://graph.microsoft.com/beta/servicePrincipals/$objectId/synchronization/jobs/validateCredentials"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
    Body = @{
        "templateId" = "dataBricks"
        "useSavedCredentials" = "false"
        "credentials"= @(
            @{"key"= "BaseAddress"; "value" = "https://$databricksInstance/api/2.0/preview/scim"},
            @{"key" = "SecretToken"; "value" = "$PatToken" }
        )
    } | ConvertTo-Json
}
$SynchronisationJobValidationRequest = try {
    Invoke-RestMethod @SynchronisationJobValidationParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}

## Save credentials
$SynchronisationSecretsParams = @{
    Method = 'PUT'
    Uri    = "https://graph.microsoft.com/beta/servicePrincipals/$objectId/synchronization/secrets"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
    Body = @{
        "value"= @(
            @{"key"= "BaseAddress"; "value" = "https://$databricksInstance/api/2.0/preview/scim"},
            @{"key" = "SecretToken"; "value" = "$PatToken" }
        )
    } | ConvertTo-Json
}
$SynchronisationSecretsRequest = try {
    Invoke-RestMethod @SynchronisationSecretsParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}

################################################
## Step 4/5
## Start provisioning job
# Assign groups to EA

if(($groupIdList.count -gt 0) -and ($null -ne $groupIdList))
{
    foreach ($g in $groupIdList) {
        $groupId = $g.id

        Write-Host "Adding $groupId to $objectId"
        $GroupRoleAssignmentParams = @{
            Method = 'POST'
            Uri    = "https://graph.microsoft.com/beta/groups/$groupId/appRoleAssignments"
            Headers = @{
                'Content-Type' = 'application/json'
                'Authorization' = "Bearer $Token"
            }
            Body = @{
                "principalId" = "$groupId"
                "resourceId" = "$objectId"
                "appRoleId" = "a34c49f1-a169-404b-a890-00b3bfdbc1d6"
            } | ConvertTo-Json
        }
        $GroupRoleAssignmentRequest = try {
            Invoke-RestMethod @GroupRoleAssignmentParams -ErrorAction Stop
        }
        catch { # if response not 200
            Write-Host -ForegroundColor:Red "Couldn't add member"
            Write-Host -ForegroundColor:Red $_
            Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
            Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
            Write-Host -ForegroundColor:Red $_.Exception.Message
        }
    }
}

## Start the provisioning job
$SynchronisationJobStartParams = @{
    Method = 'PUT'
    Uri    = "https://graph.microsoft.com/beta/servicePrincipals/$objectId/synchronization/jobs/$jobId/start"
    Headers = @{
        'Content-Type' = 'application/json'
        'Authorization' = "Bearer $Token"
    }
}
$SynchronisationJobStartRequest = try {
    Invoke-RestMethod @SynchronisationJobStartParams -ErrorAction Stop
}
catch { # if response not 200
    Write-Host -ForegroundColor:Red $_
    Write-Host -ForegroundColor:Red "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host -ForegroundColor:Red "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host -ForegroundColor:Red $_.Exception.Message
    return -1
}