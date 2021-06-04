# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $UserEmail,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $UserPassword,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $TenantId,

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

# Define Credentials
Write-Output "Defining credentials"
$secureUserPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($UserEmail, $secureUserPassword)

# Login to Databricks Workspace
Write-Output "Logging in to Databricks"
Set-DatabricksEnvironment -TenantID $TenantId -ClientID $ClientId -Credential $cred -AzureResourceID $DatabricksWorkspaceId -ApiRootUrl $DatabricksApiUrl


# *****************************************************************************
#    CREATE SECRET SCOPES
# *****************************************************************************

# Create Databricks Hive Secret Scope
Write-Output "Creating Databricks Hive Secret Scope"
$hiveSecretScopeName = "hiveSecretScope"
try {
    Write-Output "Adding secret scope"
    Add-DatabricksSecretScope -ScopeName $hiveSecretScopeName -AzureKeyVaultResourceID $HiveKeyVaultId
}
catch {
    Write-Output "Secret Scope already exists"
}
Add-DatabricksSecretScopeACL -ScopeName $hiveSecretScopeName -Principal "users" -Permission Read

# Create Databricks Log Analytics Secret Scope
Write-Output "Creating Databricks Log Analytics Secret Scope"
$logAnalyticsSecretScopeName = "logAnalyticsSecretScope"
try {
    Write-Output "Adding secret scope"
    Add-DatabricksSecretScope -ScopeName $logAnalyticsSecretScopeName -AzureKeyVaultResourceID $LogAnalyticsKeyVaultId
}
catch {
    Write-Output "Secret Scope already exists"
}
Add-DatabricksSecretScopeACL -ScopeName $logAnalyticsSecretScopeName -Principal "users" -Permission Read


# *****************************************************************************
#    EXECUTE WORKSPACE CONFIGURATION NOTEBOOK
# *****************************************************************************

# Upload Workspace Configuration Notebook
Write-Output "Uploading Workspace Configuration Notebook"
$notebookPath = "/ConfigureDatabricksWorkspace"
Import-DatabricksWorkspaceItem -Path $notebookPath -Format SOURCE -Language SCALA -LocalPath "code/databricks/ConfigureDatabricksWorkspace.scala" -Overwrite $true

# Execute Workspace Configuration Notebook as a Job
Write-Output "Executing Workspace Configuration Notebook"
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
Write-Output " - Running - "
do {
    Start-Sleep -Seconds 5
    $jobRunStatus = Get-DatabricksJobRun -JobRunID $jobInfo.run_id
} while ($jobRunStatus.end_time -eq 0)

# Check Job Result Status
Write-Output "Checking Job Result Status"
$jobResultStatus = $jobRunStatus.state.result_state
if ($jobResultStatus -eq "SUCCESS") {
    Write-Output "Job executed successfully with result status: '${jobResultStatus}'"
}
else {
    Write-Output "Job did not succeed with result status: '${jobResultStatus}'"
    throw "Job did not succeed with result status: '${jobResultStatus}'"
}

# Remove Workspace Configuration Notebook
Write-Output "Removing Workspace Configuration Notebook"
Remove-DatabricksWorkspaceItem $notebookPath


# *****************************************************************************
#    UPLOAD INIT SCRIPTS
# *****************************************************************************

# Update Spark Monitoring Shell Script
Write-Output "Updating Spark Monitoring Init Script"
$sparkMonitoringInitScriptContent = Get-Content -Path "code/databricks/applicationLogging/spark-monitoring.sh" -Encoding UTF8 -Raw
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${DatabricksSubscriptionId}"
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${DatabricksResourceGroupName}"
$sparkMonitoringInitScriptContent = $sparkMonitoringInitScriptContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${DatabricksWorkspaceName}"
$sparkMonitoringInitScriptContent | Set-Content -Path "code/databricks/applicationLogging/spark-monitoring-updated.sh" -Encoding UTF8

# Upload Spark Monitoring Shell Script
Write-Output "Uploading Spark Monitoring Shell Script"
Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark-monitoring.sh" -LocalPath "code/databricks/applicationLogging/spark-monitoring-updated.sh" -Overwrite $true

# Upload Hive Metastore Connection Shell Script
Write-Output "Uploading Hive Metastore Connection Init Script"
$hiveGlobalInitScriptName = "external-metastore"
$externalMetastoreInitScriptContent = Get-Content -Path "code/databricks/externalMetastore/external-metastore.sh" -Encoding UTF8 -Raw
try {
    Write-Output "Adding Databricks Global Init Script '${hiveGlobalInitScriptName}'"
    Add-DatabricksGlobalInitScript -Name $hiveGlobalInitScriptName -Script $externalMetastoreInitScriptContent -AsPlainText -Position 1 -Enabled $true
}
catch {
    Write-Output "Global Init Script already exists"
    Write-Output "Updating Databricks Global Init Script '${hiveGlobalInitScriptName}'"
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
        Write-Output " - Created new policy `"${PolicyName}`""
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
        Write-Output " - Updated policy `"${PolicyName}`""
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
Write-Output "Loading All-Purpose Policy"
$allPurposePolicy = Update-DatabricksClusterPolicyValues -ContentPath "code/databricks/policies/allPurposePolicy.json" -ReplacementValues $policyValues
Set-DatabricksClusterPolicy -PolicyName "AllPurposeClusterPolicy" -PolicyJson $allPurposePolicy

# Load Job Policy
Write-Output "Loading Job Policy"
$jobPolicy = Update-DatabricksClusterPolicyValues -ContentPath "code/databricks/policies/jobPolicy.json" -ReplacementValues $policyValues
Set-DatabricksClusterPolicy -PolicyName "JobClusterPolicy" -PolicyJson $jobPolicy
