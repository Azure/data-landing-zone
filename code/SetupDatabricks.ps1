# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksWorkspaceName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksWorkspaceId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksApiUrl,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksSubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $DatabricksResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HiveKeyVaultId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HiveConnectionStringSecretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HiveUsernameSecretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HivePasswordSecretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogAnalyticsKeyVaultId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogAnalyticsWorkspaceIdSecretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogAnalyticsWorkspaceKeySecretName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HiveVersion = "2.3.7",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $HadoopVersion = "2.7.4"
)

# *****************************************************************************
#    SETUP ENVIRONMENT AND LOGIN TO DATABRICKS
# *****************************************************************************

# Install Databricks PS Module
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name DatabricksPS
Update-Module -Name DatabricksPS

# Define Service Principal Credentials
Write-Host "Defining Service Principal credentials"
$password = ConvertTo-SecureString $env:servicePrincipalKey -AsPlainText -Force
$credSp = New-Object System.Management.Automation.PSCredential ($env:servicePrincipalId, $password)

# Login to Databricks Workspace using Service Principal
Write-Host "Logging in to Databricks using Service Principal"
Set-DatabricksEnvironment -TenantID $env:tenantId -ClientID $env:servicePrincipalId -Credential $credSp -AzureResourceID $DatabricksWorkspaceId -ApiRootUrl $DatabricksApiUrl -ServicePrincipal


# *****************************************************************************
#    CREATE SECRET SCOPES
# *****************************************************************************

# Create Databricks Hive Secret Scope
Write-Host "Creating Databricks Hive Secret Scope"
$hiveSecretScopeName = "hiveSecretScope"
try {
    Write-Host "Adding secret scope"
    Add-DatabricksSecretScope -ScopeName $hiveSecretScopeName -AzureKeyVaultResourceID $HiveKeyVaultId
}
catch {
    Write-Host "Secret Scope already exists"
}
Add-DatabricksSecretScopeACL -ScopeName $hiveSecretScopeName -Principal "users" -Permission Read

# Create Databricks Log Analytics Secret Scope
Write-Host "Creating Databricks Log Analytics Secret Scope"
$logAnalyticsSecretScopeName = "logAnalyticsSecretScope"
try {
    Write-Host "Adding secret scope"
    Add-DatabricksSecretScope -ScopeName $logAnalyticsSecretScopeName -AzureKeyVaultResourceID $LogAnalyticsKeyVaultId
}
catch {
    Write-Host "Secret Scope already exists"
}
Add-DatabricksSecretScopeACL -ScopeName $logAnalyticsSecretScopeName -Principal "users" -Permission Read


# *****************************************************************************
#    EXECUTE WORKSPACE CONFIGURATION NOTEBOOK
# *****************************************************************************

# Upload Workspace Configuration Notebook
Write-Host "Uploading Workspace Configuration Notebook"
$notebookPath = "/ConfigureDatabricksWorkspace"
Import-DatabricksWorkspaceItem -Path $notebookPath -Format SOURCE -Language SCALA -LocalPath "code/databricks/ConfigureDatabricksWorkspace.scala" -Overwrite $true

# Execute Workspace Configuration Notebook as a Job
Write-Host "Executing Workspace Configuration Notebook"
$runName = "WorkspaceConfigurationExecution"
$jobClusterDefinition = @{
    "spark_version" = "7.5.x-scala2.12"
    "node_type_id"  = "Standard_D3_v2"
    "num_workers"   = 1
}
$notebookParams = @{
    "hive-version"   = $HiveVersion
    "hadoop-version" = $HadoopVersion
}
$jobInfo = New-DatabricksJobRun -RunName $runName -NewClusterDefinition $jobClusterDefinition -NotebookPath $notebookPath -NotebookParameters $notebookParams

# Monitor the job status and wait for completion
do {
    Write-Host -NoNewline "`r - Running .."
    Start-Sleep -Seconds 5
    $jobRunStatus = Get-DatabricksJobRun -JobRunID $jobInfo.run_id
} while ($jobRunStatus.end_time -eq 0)

# Check Job Result Status
Write-Host "Checking Job Result Status"
$jobResultStatus = $jobRunStatus.state.result_state
if ($jobResultStatus -eq "SUCCESS") {
    Write-Host "Job executed successfully with result status: '${jobResultStatus}'"
}
else {
    Write-Host "Job did not succeed with result status: '${jobResultStatus}'"
    throw "Job did not succeed with result status: '${jobResultStatus}'"
}

# Remove Workspace Configuration Notebook
Write-Host "Removing Workspace Configuration Notebook"
Remove-DatabricksWorkspaceItem $notebookPath


# *****************************************************************************
#    UPLOAD INIT SCRIPTS
# *****************************************************************************

# Update Spark Monitoring Shell Script
Write-Host "Updating Spark Monitoring Init Script"
$sparkMonitoringInitScriptContent = Get-Content -Path "code/databricks/applicationLogging/spark-monitoring.sh" -Encoding UTF8 -Raw
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${DatabricksSubscriptionId}"
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${DatabricksResourceGroupName}"
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${DatabricksWorkspaceName}"
$sparkMonitoringInitScriptContent | Set-Content -Path "code/databricks/applicationLogging/spark-monitoring-updated.sh" -Encoding UTF8

# Upload Spark Monitoring Shell Script
Write-Host "Uploading Spark Monitoring Shell Script"
Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark-monitoring.sh" -LocalPath "code/databricks/applicationLogging/spark-monitoring-updated.sh" -Overwrite $true

# Upload Hive Metastore Connection Shell Script
Write-Host "Uploading Hive Metastore Connection Init Script"
$hiveGlobalInitScriptName = "external-metastore"
$externalMetastoreInitScriptContent = Get-Content -Path "code/databricks/externalMetastore/external-metastore.sh"
$externalMetastoreInitScriptContent = $externalMetastoreInitScriptContent -join "`r`n" | Out-String
try {
    Write-Host "Adding Databricks Global Init Script '${hiveGlobalInitScriptName}'"
    Add-DatabricksGlobalInitScript -Name $hiveGlobalInitScriptName -Script $externalMetastoreInitScriptContent -AsPlainText -Position 1 -Enabled $true
}
catch {
    Write-Host "Global Init Script already exists"
    Write-Host "Updating Databricks Global Init Script '${hiveGlobalInitScriptName}'"
    $globalInitScripts = Get-DatabricksGlobalInitScript
    $globalInitScriptId = ""
    foreach ($globalInitScript in $globalInitScripts) {
        if ($globalInitScript.name -eq $hiveGlobalInitScriptName) {
            $globalInitScriptId = $globalInitScript.script_id
            Break;
        }
    }
    Update-DatabricksGlobalInitScript -ScriptID $globalInitScriptId -Name $hiveGlobalInitScriptName -Script $externalMetastoreInitScriptContent -AsPlainText -Position 1 -Enabled $true
}


# *****************************************************************************
#    UPDATE AND UPLOAD CLUSTER POLICIES
# *****************************************************************************

# Declare a function that will update values in a policy object
function Update-DatabricksClusterPolicyValues {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $ContentPath,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        $ReplacementValues
    )
    # Load Policy
    Write-Verbose "Loading Policies"
    $policy = Get-Content -Path $ContentPath -Raw | Out-String | ConvertFrom-Json
    
    # Replace Values in Policy
    Write-Verbose "Replacing Values in Policy"
    foreach ($rv in $ReplacementValues.GetEnumerator()) {
        if ([bool]($policy.PSobject.Properties.name -match $rv.Name)) {
            $policy.$($rv.Name).value = $rv.Value
        }
    }

    # Convert Policy to JSON
    Write-Verbose "Converting Policy JSON"
    $policy = ConvertTo-Json $policy
    return $policy
}


function Set-DatabricksClusterPolicy {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $PolicyName,
        
        [Parameter(Mandatory = $true)]
        [string]
        $PolicyJson
    )

    try {
        Add-DatabricksClusterPolicy -PolicyName $PolicyName -Definition $PolicyJson
        Write-Host " - Created new policy `"${PolicyName}`""
    }
    catch {
        $clusterPolicies = Get-DatabricksClusterPolicy
        $policyId = ""
        foreach ($clusterPolicy in $clusterPolicies) {
            if ($clusterPolicy.name -eq $PolicyName) {
                $policyId = $clusterPolicy.policy_id
                Break;
            }
        }
        Update-DatabricksClusterPolicy -PolicyID $policyId -PolicyName $PolicyName -Definition $PolicyJson
        Write-Host " - Updated policy `"${PolicyName}`""
    }
}

$policyValues = @{
    "spark_env_vars.LOG_ANALYTICS_WORKSPACE_ID"  = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceIdSecretName}}}"
    "spark_env_vars.LOG_ANALYTICS_WORKSPACE_KEY" = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceKeySecretName}}}"
    "spark_env_vars.SQL_USERNAME"                = "{{secrets/${hiveSecretScopeName}/${HiveUsernameSecretName}}}"
    "spark_env_vars.SQL_PASSWORD"                = "{{secrets/${hiveSecretScopeName}/${HivePasswordSecretName}}}"
    "spark_env_vars.SQL_CONNECTION_STRING"       = "{{secrets/${hiveSecretScopeName}/${HiveConnectionStringSecretName}}}"
    "spark_env_vars.HIVE_VERSION"                = "${HiveVersion}"
}

# Load All-Purpose Policy
Write-Host "Loading All-Purpose Policy"
$allPurposePolicy = Update-DatabricksClusterPolicyValues -ContentPath "code/databricks/policies/allPurposePolicy.json" -ReplacementValues $policyValues
Set-DatabricksClusterPolicy -PolicyName "AllPurposeClusterPolicy" -PolicyJson $allPurposePolicy

# Load Job Policy
Write-Host "Loading Job Policy"
$jobPolicy = Update-DatabricksClusterPolicyValues -ContentPath "code/databricks/policies/jobPolicy.json" -ReplacementValues $policyValues
Set-DatabricksClusterPolicy -PolicyName "JobClusterPolicy" -PolicyJson $jobPolicy
