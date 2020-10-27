# Define script arguments
param (
    [Parameter(Mandatory = $true)]
    [String]
    $databricksDetails,

    [Parameter(Mandatory = $true)]
    [String]
    $hivemetastoreDetails,

    [Parameter(Mandatory = $true)]
    [String]
    $keyVaultId,

    [Parameter(Mandatory = $true)]
    [String]
    $logAnalyticsWorkspaceId,

    [Parameter(Mandatory = $true)]
    [String]
    $logAnalyticsWorkspaceKey,

    [Parameter(Position=1, ValueFromRemainingArguments)]
    $Remaining
)

# Install Databricks PS Module
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name DatabricksPS

# Define Service Principal Credentials
Write-Host "Defining Service Principal credentials"
$password = ConvertTo-SecureString $env:servicePrincipalKey -AsPlainText -Force
$credSp = New-Object System.Management.Automation.PSCredential ($env:servicePrincipalId, $password)

# Parse Databricks Details
Write-Host "Parsing Databricks Details"
$databricksDetailsObject = ConvertFrom-Json $databricksDetails
$databricksWorkspaceName = $databricksDetailsObject.databricksWorkspaceName.value
$databricksWorkspaceId = $databricksDetailsObject.databricksWorkspaceId.value
$databricksApiUrl = $databricksDetailsObject.databricksApiUrl.value
$databricksSubscriptionId = $databricksDetailsObject.subscriptionId.value
$databricksResourceGroupName = $databricksDetailsObject.resourceGroupName.value

# Parse HiveMetastore Details
Write-Host "Parsing HiveMetastore Details"
$hiveMetastoreDetailsObject = = ConvertFrom-Json $hiveMetastoreDetails
$sqlServerName = $hiveMetastoreDetailsObject.sqlServerName.value
$sqlDatabaseName = $hiveMetastoreDetailsObject.sqlDatabaseName.value
$sqlServerUsername = $hiveMetastoreDetailsObject.sqlServerAdministratorLoginUsername.value
$sqlServerPassword = $hiveMetastoreDetailsObject.sqlServerAdministratorLoginPassword.value

# Login to Databricks Workspace using Service Principal
Write-Host "Logging in to Databricks using Service Principal"
Set-DatabricksEnvironment -TenantID $env:tenantId -ClientID $env:servicePrincipalId -Credential $credSp -AzureResourceID $databricksWorkspaceId -ApiRootUrl $databricksApiUrl -ServicePrincipal

# Generate Databricks PAT Token
Write-Host "Generating Databricks PAT Token"
$patToken = Add-DatabricksApiToken -LifetimeSeconds 1200 -Comment "Databricks Token for Setup"

# Login to Databricks Workspace using PAT Token
Write-Host "Logging in to Databricks using PAT Token"
Set-DatabricksEnvironment -AccessToken $patToken.token_value -ApiRootUrl $databricksApiUrl

# Create Databricks Secret Scope
Write-Host "Creating Databricks Secret Scope"
$secretScopeName = "adminSecretScopeNew"
try {
    Write-Host "Add secret scope"
    Add-DatabricksSecretScope -ScopeName $secretScopeName
}
catch {
    Write-Host "Secret Scope already exists"
}
Add-DatabricksSecretScopeACL -ScopeName $secretScopeName -Principal "users" -Permission Read

# Add secrets to secret scope
Write-Host "Adding Secrets to Secret Scope"
$sqlServerConnectionURL = "jdbc:sqlserver://${sqlServerName}.database.windows.net:1433;database=${sqlDatabaseName};"
Add-DatabricksSecret -ScopeName $secretScopeName -SecretName "logAnalyticsWorkspaceId" -StringValue $logAnalyticsWorkspaceId
Add-DatabricksSecret -ScopeName $secretScopeName -SecretName "logAnalyticsWorkspaceKey" -StringValue $logAnalyticsWorkspaceKey
Add-DatabricksSecret -ScopeName $secretScopeName -SecretName "hiveMetastoreConnectionUserName" -StringValue $sqlServerUsername
Add-DatabricksSecret -ScopeName $secretScopeName -SecretName "hiveMetastoreConnectionPassword" -StringValue $sqlServerPassword
Add-DatabricksSecret -ScopeName $secretScopeName -SecretName "hiveMetastoreConnectionURL" -StringValue $sqlServerConnectionURL

# Update Spark Monitoring Shell Script
Write-Host "Updating Spark Monitoring Shell Script"
$SparkMonitoringFileContent = Get-Content -Path "code/applicationLogging/spark-monitoring.sh"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_SUBSCRIPTION_ID=", "AZ_SUBSCRIPTION_ID=${databricksSubscriptionId}"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_RSRC_GRP_NAME=", "AZ_RSRC_GRP_NAME=${databricksResourceGroupName}"
$SparkMonitoringFileContent = $SparkMonitoringFileContent -Replace "AZ_RSRC_NAME=", "AZ_RSRC_NAME=${databricksWorkspaceName}"
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

# Upload Spark Monitoring Jar for testing
Write-Host "Uploading Spark Monitoring Jar for testing"
Upload-DatabricksFSFile -Path "/FileStore/job-jars/spark-monitoring-sample-1.0.0.jar" -LocalPath "code/applicationLogging/tests/spark-monitoring-sample-1.0.0.jar" -Overwrite $true

# Add Databricks Job for testing logging
Write-Host "Add Databricks Job for testing logging"
$jobName = "LogAnalyticsLoggingTest"
$jobClusterDefinition = @{
    "spark_version" = "6.6.x-scala2.11"
    "node_type_id" = "Standard_D3_v2"
    "num_workers" = 1
}
$jobLibraries = @( @{"jar" = "dbfs:/databricks/spark-monitoring/tests/spark-monitoring-sample-1.0.0.jar"} )
$jobJarUri = "spark-monitoring-sample-1.0.0.jar"
$jobJarMainClassName = "com.microsoft.pnp.samplejob.StreamingQueryListenerSampleJob"
Add-DatabricksJob -Name $jobName -NewClusterDefinition $jobClusterDefinition -Libraries $jobLibraries -JarMainClassName $jobJarMainClassName -JarURI $jobJarUri

# Load General Cluster Policy
Write-Host "Loading General Cluster Policy"
$generalPolicy = Get-Content -Path "code/policies/generalPolicy.json" -Raw | Out-String | ConvertFrom-Json
$generalPolicy = ConvertTo-Json $generalPolicy

# Define General Cluster Policy
Write-Host "Defining General Cluster Policy"
$policyName = "GeneralClusterPolicyNew"
try {
    Add-DatabricksClusterPolicy -PolicyName $policyName -Definition $generalPolicy
}
catch {
    $clusterPolicies = Get-DatabricksClusterPolicy
    $clusterId = ""
    foreach ($clusterPolicy in $clusterPolicies) {
        if ($clusterPolicy.name -eq $policyName) {
            $clusterId = $clusterPolicy.policy_id
            Break;
        }
    }
    Update-DatabricksClusterPolicy -PolicyID $clusterId -PolicyName $policyName -Definition $generalPolicy
}

# Test connection to Databricks
# Write-Host "Testing connection to Databricks"
# Test-DatabricksEnvironment
