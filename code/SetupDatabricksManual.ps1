# Define script arguments
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $UserObjectId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $Password,

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
    $HadoopVersion = "2.7.4",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $MySqlId
)

# *****************************************************************************
#    RESTART MYSQL SERVER
# *****************************************************************************

az mysql server restart --ids "${MySqlId}"


# *****************************************************************************
#    SETUP ENVIRONMENT AND LOGIN TO DATABRICKS
# *****************************************************************************

# Install Databricks PS Module
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name DatabricksPS

# Define Service Principal Credentials
Write-Host "Defining Service Principal credentials"
$password = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($UserObjectId, $password)

# Login to Databricks Workspace
Write-Host "Logging in to Databricks"
Set-DatabricksEnvironment -TenantID $TenantId -ClientID $UserObjectId -Credential $cred -AzureResourceID $DatabricksWorkspaceId -ApiRootUrl $DatabricksApiUrl


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
Write-Host "`r - Notebook execution complete!  Status: $($jobRunStatus.state.result_state)"
if ($jobRunStatus.state.result_state -eq "FAILED") {
    Write-Host "       $($jobRunStatus.state.state_message)`n"
}

# Clean up notebook
Write-Host "Removing Workspace Configuration Notebook"
Remove-DatabricksWorkspaceItem $notebookPath


# *****************************************************************************
#    UPLOAD GLOBAL INIT SCRIPTS
# *****************************************************************************

# Update Spark Monitoring Shell Script
Write-Host "Updating Spark Monitoring Init Script"
$SparkMonitoringInitScriptContent = Get-Content -Path "code/databricks/applicationLogging/spark-monitoring.sh"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${DatabricksSubscriptionId}"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${DatabricksResourceGroupName}"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${DatabricksWorkspaceName}"
$SparkMonitoringInitScriptContent | Set-Content -Path "code/databricks/applicationLogging/spark-monitoring.sh"

# Upload Spark Monitoring Shell Script
Write-Host "Uploading Spark Monitoring Shell Script"
Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark-monitoring.sh" -LocalPath "code/databricks/applicationLogging/spark-monitoring.sh" -Overwrite $true

# Upload Hive Metastore Connection Shell Script
Write-Host "Uploading Hive Metastore Connection Init Script"
$ExternalMetastoreInitScriptContent = Get-Content -Path "code/databricks/externalMetastore/external-metastore.sh"
$ExternalMetastoreInitScriptContent = $ExternalMetastoreInitScriptContent -join "`r`n" | Out-String
$scriptInfo = Add-DatabricksGlobalInitScript -Name "external-metastore" -Script $ExternalMetastoreInitScriptContent -AsPlainText -Position 1 -Enabled $true


# *****************************************************************************
#    UPDATE AND UPLOAD CLUSTER POLICIES
# *****************************************************************************

# Declare a function that will update values in a policy object
function Update-DatabricksClusterPolicyValues {
    param (
        [Parameter(Mandatory)]
        [String]
        $ContentPath,

        [Parameter(Mandatory)]
        [Hashtable]
        $ReplacementValues
    )

    $policy = Get-Content -Path $ContentPath -Raw | Out-String | ConvertFrom-Json
    
    foreach ($rv in $ReplacementValues.GetEnumerator()) {
        if ([bool]($policy.PSobject.Properties.name -match $rv.Name)) {
            $policy.$($rv.Name).value = $rv.Value
        }
    }

    ConvertTo-Json $policy
}

# Declare a wrapper function for uploading a new policy or updating an existing policy
function Set-DatabricksClusterPolicy {
    param (
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter(Mandatory)][string]$PolicyJson
    )

    try {
        Add-DatabricksClusterPolicy -PolicyName $PolicyName -Definition $PolicyJson
        Write-Host "  - Create new policy `"${PolicyName}`""
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
        Write-Host "  - Updated policy `"${PolicyName}`""
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
