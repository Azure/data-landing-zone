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
    $LogAnalyticsWorkspaceKeySecretName
)

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

# Update Spark Monitoring Shell Script
Write-Host "Updating Spark Monitoring Shell Script"
$SparkMonitoringFileContent = Get-Content -Path "code/applicationLogging/spark-monitoring.sh"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${DatabricksSubscriptionId}"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${DatabricksResourceGroupName}"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${DatabricksWorkspaceName}"
$SparkMonitoringFileContent | Set-Content -Path "code/applicationLogging/spark-monitoring.sh"

# Upload Hive Metastore Connection Shell Script
Write-Host "Uploading Hive Metastore Connection Shell Script"
Upload-DatabricksFSFile -Path "/databricks/externalMetastore/external-metastore.sh" -LocalPath "code/externalMetastore/external-metastore.sh" -Overwrite $true

# Upload Spark Monitoring Shell Script
Write-Host "Uploading Spark Monitoring Shell Script"
Upload-DatabricksFSFile -Path "/databricks/spark-monitoring/spark-monitoring.sh" -LocalPath "code/applicationLogging/spark-monitoring.sh" -Overwrite $true

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

# Upload Jars for Hive Metastore 1.2.1
Write-Host "Uploading Jars for Hive Metastore 1.2.1"
$basePath = "code/externalMetastore/hiveMetastoreJars_1.2.1/"
$relativeFilePaths = Get-ChildItem -Path $basePath -Recurse -File -Name
foreach ($relativeFilePath in $relativeFilePaths) {
    Write-Host "Uploading File: $file"
    Upload-DatabricksFSFile -Path "/hiveMetastoreJars_1.2.1/${relativeFilePath}" -LocalPath "${basePath}${relativeFilePath}" -Overwrite $true
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

# Update Cluster Policy
Write-Host "Updating Cluster Policies"
$connectionUrlParameter = "spark_env_vars.SQL_CONNECTION_STRING"
$userNameParameter = "spark_env_vars.SQL_USERNAME"
$passwordParameter = "spark_env_vars.SQL_PASSWORD"
$logAnalyticsWorkspaceIdParameter = "spark_env_vars.LOG_ANALYTICS_WORKSPACE_ID"
$logAnalyticsWorkspaceKeyParameter = "spark_env_vars.LOG_ANALYTICS_WORKSPACE_KEY"

# Load All Purpose Policy
Write-Host "Loading All Purpose Policy"
$allPurposePolicy = Get-Content -Path "code/policies/allPurposePolicy.json" -Raw | Out-String | ConvertFrom-Json
$allPurposePolicy.$connectionUrlParameter.value = "{{secrets/${hiveSecretScopeName}/${HiveConnectionStringSecretName}}}"
$allPurposePolicy.$userNameParameter.value = "{{secrets/${hiveSecretScopeName}/${HiveUsernameSecretName}}}"
$allPurposePolicy.$passwordParameter.value = "{{secrets/${hiveSecretScopeName}/${HivePasswordSecretName}}}"
$allPurposePolicy.$logAnalyticsWorkspaceIdParameter.value = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceIdSecretName}}}"
$allPurposePolicy.$logAnalyticsWorkspaceKeyParameter.value = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceKeySecretName}}}"
$allPurposePolicy = ConvertTo-Json $allPurposePolicy

# Define All Purpose Policy
Write-Host "Defining All Purpose Cluster Policy"
$allPurposePolicyName = "AllPurposeClusterPolicy"
try {
    Add-DatabricksClusterPolicy -PolicyName $allPurposePolicyName -Definition $allPurposePolicy
}
catch {
    $clusterPolicies = Get-DatabricksClusterPolicy
    $clusterId = ""
    foreach ($clusterPolicy in $clusterPolicies) {
        if ($clusterPolicy.name -eq $allPurposePolicyName) {
            $clusterId = $clusterPolicy.policy_id
            Break;
        }
    }
    Update-DatabricksClusterPolicy -PolicyID $clusterId -PolicyName $allPurposePolicyName -Definition $allPurposePolicy
}

# Load Job Policy
Write-Host "Loading Job Policy"
$jobPolicy = Get-Content -Path "code/policies/jobPolicy.json" -Raw | Out-String | ConvertFrom-Json
$jobPolicy.$connectionUrlParameter.value = "{{secrets/${hiveSecretScopeName}/${HiveConnectionStringSecretName}}}"
$jobPolicy.$userNameParameter.value = "{{secrets/${hiveSecretScopeName}/${HiveUsernameSecretName}}}"
$jobPolicy.$passwordParameter.value = "{{secrets/${hiveSecretScopeName}/${HivePasswordSecretName}}}"
$jobPolicy.$logAnalyticsWorkspaceIdParameter.value = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceIdSecretName}}}"
$jobPolicy.$logAnalyticsWorkspaceKeyParameter.value = "{{secrets/${logAnalyticsSecretScopeName}/${LogAnalyticsWorkspaceKeySecretName}}}"
$jobPolicy = ConvertTo-Json $jobPolicy

# Define Job Policy
Write-Host "Defining Job Cluster Policy"
$jobPolicyName = "JobClusterPolicy"
try {
    Add-DatabricksClusterPolicy -PolicyName $jobPolicyName -Definition $jobPolicy
}
catch {
    $clusterPolicies = Get-DatabricksClusterPolicy
    $clusterId = ""
    foreach ($clusterPolicy in $clusterPolicies) {
        if ($clusterPolicy.name -eq $jobPolicyName) {
            $clusterId = $clusterPolicy.policy_id
            Break;
        }
    }
    Update-DatabricksClusterPolicy -PolicyID $clusterId -PolicyName $jobPolicyName -Definition $jobPolicy
}

Write-Host "Successfully finished Databricks setup"