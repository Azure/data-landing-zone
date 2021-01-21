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
#    SETUP AND LOGIN
# *****************************************************************************

# Install Databricks PS Module
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name DatabricksPS

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
$notebookPath = "/Configure Databricks Workspace"
Import-DatabricksWorkspaceItem -Path $notebookPath -Format SOURCE -Language SCALA -LocalPath "code/Configure Databricks Workspace.scala" -Overwrite $true

# Execute Workspace Configuration Notebook as a Job
Write-Host "Executing Workspace Configuration Notebook"
$runName = "WorkspaceConfigurationExecution"
$jobClusterDefinition = @{
     "spark_version" = "7.5.x-scala2.12"
     "node_type_id" = "Standard_D3_v2"
     "num_workers" = 1
}
$notebookParams = @{
    "hive-version" = $HiveVersion
    "hadoop-version" = $HadoopVersion
}
$jobInfo = New-DatabricksJobRun -RunName $runName -NewClusterDefinition $jobClusterDefinition -NotebookPath $notebookPath -NotebookParameters $notebookParams

# Monitor the job status and wait for completion
do {
    Write-Host "  - Running..."
    Start-Sleep -Seconds 10
    $jobRunStatus = Get-DatabricksJobRun -JobRunID $jobInfo.run_id
} while ($jobRunStatus.end_time -eq 0)
Write-Host "  - Notebook execution complete!  Status: $($jobRunStatus.state.result_state)"
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
$SparkMonitoringInitScriptContent = Get-Content -Path "code/applicationLogging/spark-monitoring.sh"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${DatabricksSubscriptionId}"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${DatabricksResourceGroupName}"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${DatabricksWorkspaceName}"
$SparkMonitoringInitScriptContent = $SparkMonitoringInitScriptContent -join "`r`n" | Out-String

# Upload Spark Monitoring Shell Script
Write-Host "Uploading Spark Monitoring Shell Script"
$scriptInfo = Add-DatabricksGlobalInitScript -Name "spark-monitoring" -Script $SparkMonitoringInitScriptContent -AsPlainText -Position 0 -Enabled $true

# Upload Hive Metastore Connection Shell Script
Write-Host "Uploading Hive Metastore Connection Init Script"
$ExternalMetastoreInitScriptContent = Get-Content -Path "code/externalMetastore/external-metastore.sh"
$ExternalMetastoreInitScriptContent = $ExternalMetastoreInitScriptContent -join "`r`n" | Out-String
$scriptInfo = Add-DatabricksGlobalInitScript -Name "external-metastore" -Script $ExternalMetastoreInitScriptContent -AsPlainText -Position 1 -Enabled $true


# *****************************************************************************
#    UPLOAD SPARK MONITORING JARS
# *****************************************************************************

# Upload Jars for Spark 2.4.3
Write-Host "Uploading Spark Monitoring Jars for Spark 2.4.3"
$basePath = "code/applicationLogging/spark_2.4.3/"
$relativeFilePaths = Get-ChildItem -Path $basePath -Recurse -File -Name
foreach ($relativeFilePath in $relativeFilePaths) {
    Write-Host "Uploading File: $file"
    Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark_2.4.3/${relativeFilePath}" -LocalPath "${basePath}${relativeFilePath}" -Overwrite $true
}

# Upload Jars for Spark 2.4.5
Write-Host "Uploading Spark Monitoring Jars for Spark 2.4.5"
$basePath = "code/applicationLogging/spark_2.4.5/"
$relativeFilePaths = Get-ChildItem -Path $basePath -Recurse -File -Name
foreach ($relativeFilePath in $relativeFilePaths) {
    Write-Host "Uploading File: $file"
    Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark_2.4.5/${relativeFilePath}" -LocalPath "${basePath}${relativeFilePath}" -Overwrite $true
}

# Upload Jars for Spark 3.0.0
Write-Host "Uploading Spark Monitoring Jars for Spark 3.0.0"
$basePath = "code/applicationLogging/spark_3.0.0/"
$relativeFilePaths = Get-ChildItem -Path $basePath -Recurse -File -Name
foreach ($relativeFilePath in $relativeFilePaths) {
    Write-Host "Uploading File: $file"
    Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark_3.0.0/${relativeFilePath}" -LocalPath "${basePath}${relativeFilePath}" -Overwrite $true
}

# Upload Jars for Spark 3.0.1
Write-Host "Uploading Spark Monitoring Jars for Spark 3.0.1"
$basePath = "code/applicationLogging/spark_3.0.1/"
$relativeFilePaths = Get-ChildItem -Path $basePath -Recurse -File -Name
foreach ($relativeFilePath in $relativeFilePaths) {
    Write-Host "Uploading File: $file"
    Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark_3.0.1/${relativeFilePath}" -LocalPath "${basePath}${relativeFilePath}" -Overwrite $true
}

# # Upload Spark Monitoring Jar for testing
# Write-Host "Uploading Spark Monitoring Jar for testing"
# Upload-DatabricksFSFile -Path "/FileStore/job-jars/spark-monitoring-sample-1.0.0.jar" -LocalPath "code/applicationLogging/tests/spark-monitoring-sample-1.0.0.jar" -Overwrite $true

# # Add Databricks Job for testing logging
# Write-Host "Add Databricks Job for testing logging"
# $jobName = "LogAnalyticsLoggingTest"
# $jobClusterDefinition = @{
#     "spark_version" = "6.6.x-scala2.11"
#     "node_type_id" = "Standard_D3_v2"
#     "num_workers" = 1
# }
# $jobLibraries = @( @{"jar" = "dbfs:/databricks/spark-monitoring/tests/spark-monitoring-sample-1.0.0.jar"} )
# $jobJarUri = "spark-monitoring-sample-1.0.0.jar"
# $jobJarMainClassName = "com.microsoft.pnp.samplejob.StreamingQueryListenerSampleJob"
# Add-DatabricksJob -Name $jobName -NewClusterDefinition $jobClusterDefinition -Libraries $jobLibraries -JarMainClassName $jobJarMainClassName -JarURI $jobJarUri


# *****************************************************************************
#    UPLOAD CLUSTER POLICIES
# *****************************************************************************

# Declare a function that will update values in a policy object
function Update-PolicyValues {
    param (
        [Parameter(Mandatory)][string]$ContentPath,
        [Parameter(Mandatory)][Hashtable]$ReplacementValues
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
function Upload-Policy {
    param (
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter(Mandatory)][string]$PolicyJson
    )

    try {
        Add-DatabricksClusterPolicy -PolicyName $PolicyName -Definition $PolicyJson
        Write-Host "  - Create new policy `"$PolicyName`""
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
        Write-Host "  - Updated policy `"$PolicyName`""
    }
}

$policyValues = @{
    "spark_env_vars.LOG_ANALYTICS_WORKSPACE_ID" = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceIdSecretName}}}"
    "spark_env_vars.LOG_ANALYTICS_WORKSPACE_KEY" = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceKeySecretName}}}"
    "spark_conf.spark.hadoop.javax.jdo.option.ConnectionUserName" = "{{secrets/${hiveSecretScopeName}/${HiveUsernameSecretName}}}"
    "spark_conf.spark.hadoop.javax.jdo.option.ConnectionPassword" = "{{secrets/${hiveSecretScopeName}/${HivePasswordSecretName}}}"
    "spark_conf.spark.hadoop.javax.jdo.option.ConnectionURL" = "{{secrets/${hiveSecretScopeName}/${HiveConnectionStringSecretName}}}"
    "spark_conf.spark.sql.hive.metastore.version" = "$HiveVersion"
}

# Load All-Purpose Policy
Write-Host "Loading All-Purpose Policy"
$allPurposePolicy = Update-PolicyValues -ContentPath "code/policies/allPurposePolicy.json" -ReplacementValues $policyValues
Upload-Policy -PolicyName "AllPurposeClusterPolicy" -PolicyJson $allPurposePolicy

# Load Job Policy
Write-Host "Loading Job Policy"
$jobPolicy = Update-PolicyValues -ContentPath "code/policies/jobPolicy.json" -ReplacementValues $policyValues
Upload-Policy -PolicyName "JobClusterPolicy" -PolicyJson $jobPolicy
