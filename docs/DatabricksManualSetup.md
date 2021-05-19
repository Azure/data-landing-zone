# Manual Azure Databricks Setup

## Blockers

Due to the following service limitations, Databricks needs to be setup manually:

- Creating a Key Vault backed Databricks secret scope is not possible via Service Principle. The issue can be tracked [here](https://github.com/databricks/databricks-cli/issues/338).

## Manual Databricks configuration

Due to the issue mentioned above, we cannot rely on the application workflow, but only rely on the on-behalf workflow. This means, that instead of using a Service Principle for authentication, we need to rely on a user being authenticated against the workspace. Only then, we can use the Databricks API to create a Key Vault backed secret scopes. If you are ok with Databricks backed secret scopes, then you can already automate the complete setup end-to-end. However, for manageability reasons, we are recommending to use Key Vaults for storing secrets.

In order to simplify the manual setup and configuration of Databricks, we are providing a Powershell script (`SetupDatabricksManually.ps1`) as well as pre-defined commands in the DevOps and GitHub workflows. You can copy and paste these commands into your Powershell console to setup your Databricks workspaces manually by executing a single script. The Powershell script will perform the following actions in your Databricks workspace:

1. Setup of Key Vault backed secret scopes and the respective ACLs. These secret scopes store the credentials that are required for connecting to the external Hive metastore as well as the Log Analytics workspace.
2. Execution of a Databricks Notebook to achieve the following:
    - Download of Jar Files from maven, which are required for connecting to the external Hive metastore. This will allow you to access the external Hive metastore, even if maven is down.
    - Download and build of jars required for [application logging](https://github.com/mspnp/spark-monitoring) in Databricks.
3. Configuration, upload and setup of init scripts for application logging (cluster init script) and external Hive metastore connection (global init script).
4. Setup of Databricks cluster policies to enforce settings across all clusters in the workspace.

## Prerequisites

The following prerequisites are required before executing the Powershell script:

1. First, you have to create an AAD application as described in [this subsection](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token#configure-an-app-in-azure-portal). Please take note of the **Application (client) ID** and the **Directory (tenant) ID** of the AAD application, after executing the steps successfully.
2. You need to have **Owner** or **Contributor** access rights to the Databricks workspace.

## Execution of Powershell script

After deploying the Data Landing Zone successfully, execute the following steps:

1. Go to the workflow execution logs and look for a step called **Setup Databricks 00X - Manual Step - Guidance**. Click on that step and look into the logs. In the logs you will find the following comment:

```powershell
# Please run the following Powershell command to setup Databricks Workspace 00X

./code/SetupDatabricksManually.ps1 `
    -UserEmail '{userEmail}' `
    -UserPassword '{password}' `
    -ClientId '{clientId}' `
    -TenantId '{tenantId}' `
    -DatabricksWorkspaceName 'No Changes Required' `
    -DatabricksWorkspaceId 'No Changes Required' `
    -DatabricksApiUrl 'No Changes Required' `
    -DatabricksSubscriptionId 'No Changes Required' `
    -DatabricksResourceGroupName 'No Changes Required' `
    -HiveKeyVaultId 'No Changes Required' `
    -HiveConnectionStringSecretName 'No Changes Required' `
    -HiveUsernameSecretName 'No Changes Required' `
    -HivePasswordSecretName 'No Changes Required' `
    -LogAnalyticsKeyVaultId 'No Changes Required' `
    -LogAnalyticsWorkspaceIdSecretName 'No Changes Required' `
    -LogAnalyticsWorkspaceKeySecretName 'No Changes Required' `
    -HiveVersion '2.3.7' `
    -HadoopVersion '2.7.4'
```

2. Copy the command into Notepad or any other tool and replace the following values accordingly:

| Value       | Target |
|:------------|:------------|
| {userEmail} | Replace with your user E-Mail address. |
| {password}  | Replace with your user password. |
| {clientId}  | Replace with the **Application (client) ID** of your AAD application. |
| {tenantId}  | Replace with the **Directory (tenant) ID** of your AAD application. |

3. Clone the repository and open your Powershell console in the root of the cloned repository.
4. Copy and paste the command into your Powershell console and execute the command.
5. Watch the output in the Powershell console and see how the different setup steps are executed one after another.
