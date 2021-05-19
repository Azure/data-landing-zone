# Databricks - Provision users and groups using SCIM

Azure Databricks supports SCIM, or System for Cross-domain Identity Management, an open standard that allows automation of user provisioning. SCIM lets you use an identity provider (IdP) to create users in Azure Databricks and give them the proper level of access and remove access (deprovision them) when they leave an organization or no longer need access to Azure Databricks. One can also invoke the SCIM API directly to manage provisioning. Some user management, like temporary deactivation and reactivation, can only be performed using the SCIM API.

## Prerequisites

- Databricks Workspace
- Global Administrator rights for Azure AD

## Setup Databricks Scim Enterprise Application

1. Generate a Databricks Personal Access Token. A detailed step by step guidance can be found [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/authentication#--generate-a-personal-access-token).
2. Create an AAD Application/Service Principal. A detailed step by step guidance can be found [here](https://docs.microsoft.com/en-us/azure/databricks/dev-tools/api/latest/aad/app-aad-token#configure-an-app-in-azure-portal). Instead of granting it the `AzureDatabricks` API permission, grant it the following API permissions:
    - Microsoft Graph > Application permissions > Directory.Readwrite.All
    - Microsoft Graph > Application permissions > Application.Readwrite.Ownedby
    - Microsoft Graph > Application permissions > Application.ReadWrite.All
3. Take note of the following environment parameters of your Databricks workspace and the previously registered AAD application:
    - Tenant ID
    - Client ID and Secret of the Application
    - Databricks Workspace Name, Instance Name (e.g. `adb-5555555555555555.19.azuredatabricks.net`), Personal Access Token
    - Notification Email address, which will be used to send messaged, if the synchronization fails.
    - Optional AAD User or Security Group Object IDs.
4. Clone the repository and execute the following PowerShell command from the root folder of the repository:

```powershell
./code/aadScim/DatabricksScimSetup.ps1 `
    -TenantId '{tenantId}' `
    -ClientId '{clientId}' `
    -ClientSecret '{clientSecret}' `
    -DatabricksWorkspaceName '{databricksWorkspaceName}' `
    -DatabricksInstanceName '{databricksInstanceName}' `
    -DatabricksPatToken '{databricksPatToken}' `
    -NotificationEmail '{notificationEmail}' `
    -GroupIdList @('{objectId1}', '{objectId2}', ...)
```

This script will automatically setup the AAD Enterprise Application for the SCIM synch. If you want to synch additional groups to your Databricks workspace, then go to the Enterprise Application with the name `{databricksWorkspaceName}-scim` and follow [these steps](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/users-groups/scim/aad#assign-users-and-groups-to-the-application).
