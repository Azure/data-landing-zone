# Enterprise Scale Analytics - Data Landing Zone

> **General disclaimer** Please be aware that this template is in public preview. Therefore, expect smaller bugs and issues when working with the solution. Please submit an Issue, if you come across any issues that you would like us to fix.


# Quickstart

| Data Landing Zone |
|:--------------|
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-node%2Fmain%2Fdocs%2Freference%2Fdeploy.dataNode.json)

# Description 
A Data Landing Zone has several layers to enable agility to service the Data Domains under the node. A new Data Landing Zone is always deployed with a standard set of services to enable the entity to start ingesting and analysing data.

## What will be deployed?

By default, all the services which comes under Data Landing Zone are enabled and you must explicitly disable them if you don't want it to be deployed. 

<p align="center">
  <img src="./docs/media/DataNode.png" alt="Data Landing Zone" width="600"/>
</p>

 - [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)
 - [Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
 - [Route Tables](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
 - [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general)
 - [Storage Account](https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview)
 - [Data Lake Storage Gen2](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
 - [Azure Data Factory](https://docs.microsoft.com/en-us/azure/data-factory/)
 - [Self Hosted Integration Runtime](https://docs.microsoft.com/en-us/azure/data-factory/create-self-hosted-integration-runtime)
 - [Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/learn/quick-create-workspace)
 - [SQL Server](https://docs.microsoft.com/en-us/sql/sql-server/?view=sql-server-ver15)
 - [Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/)
 - [Synapse Workspace](https://docs.microsoft.com/en-us/azure/synapse-analytics/)
 - [Azure Databricks](https://docs.microsoft.com/en-us/azure/databricks/)
 - [Event Hub](https://docs.microsoft.com/en-us/azure/event-hubs/)

    
# Getting started

## 1. Prerequisites

The following prerequisites are required to make this repository work:
- At least 1 Azure subscription used as Data Landing Zone which is connected to the Data Management Subscription 
- Contributor access to the Azure subscription
If you don’t have an Azure subscription, create a free account before you begin. Try the [free version of Azure](https://azure.microsoft.com/en-in/free/).

## 2. Create repository from a template
TODO - add screenshots
1. On GitHub Enterprise Server, navigate to the main page of the repository.
2. Above the file list, click **Use this template**
3. Use the **Owner** drop-down menu, and select the account you want to own the repository.
4. Type a name for your repository, and an optional description.
5. Choose a repository visibility. 
6. Optionally, to include the directory structure and files from all branches in the template, and not just the default branch, select **Include all branches**.
7. Click **Create repository from template**.

## 3. Setting up the required secrets

A service principal needs to be generated for authentication and getting access to your Azure subscription. Just go to the Azure Portal to find the details of your resource group or workspace. Then start the Cloud CLI or install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) on your computer and execute the following command to generate the required credentials:

```sh
# Replace {service-principal-name}, {subscription-id} and {resource-group} with your 
# Azure subscription id and resource group name and any name for your service principle
az ad sp create-for-rbac --name {service-principal-name} \
                         --role contributor \
                         --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
                         --sdk-auth
```

This will generate the following JSON output:

```sh
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  (...)
}
```

Add this JSON output as [a secret](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets#creating-encrypted-secrets) with the name `AZURE_CREDENTIALS` in your GitHub repository:

<p align="center">
  <img src="docs/media/.png" alt="GitHub Template repository" width="700"/>
</p>

To do so, click on the Settings tab in your repository, then click on Secrets and finally add the new secret with the name `AZURE_CREDENTIALS` to your repository.

Please follow [this link](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets#creating-encrypted-secrets) for more details. 
# Parameter Update Process

In order to connect GitHub actions to the desired Azure account and deploy the resources with your preffered inputs, you'll need to modify the parameters in the ARM parameter files. As updating each parameter file manually is a time consuming process, which could lead as well to undesired user errors, you can simplify the process by running the updateParameters.yml file. <a href="/.github/.workflows/updateParameters.yml">`/.github/.workflows/updateParameters.yml"` file</a>. Just click on the link and edit the following environment variables: 

```sh
env:
  GLOBAL_DNS_RESOURCE_GROUP_ID: '<my-global-dns-resource-group-resource-id>'
  DATA_LANDING_ZONE_SUBSCRIPTION_ID: '<my-data-landing-zone-subscription-id>'
  DATA_LANDING_ZONE_NAME: '<my-data-landing-zone-name>'  # Choose ~5 characters. Will be used as a prefix for services. If not unique, deployment can fail for some services.
  LOCATION: '<my-region>'
  SYNAPSE_STORAGE_ACCOUNT_NAME: '<my-synapse-storage-account-name>'
  SYNAPSE_STORAGE_ACCOUNT_FILE_SYSTEM_NAME: '<my-synapse-storage-account-file-system-name>'
  AZURE_RESOURCE_MANAGER_CONNECTION_NAME: '<my-resource-manager-connection-name>'
  HUB_VNET_ID: '<my-hub-vnet-id>'
```

| Parameter | Description 
|:-------------------------|:-------------|:-------------|------|
| GLOBAL_DNS_RESOURCE_GROUP_ID | The global DNS Resource group resource ID which is inside the Data Management Subscription|
| DATA_LANDING_ZONE_SUBSCRIPTION_ID | The subscription ID of the Data Landing Zone where all the resources will be deployed
| DATA_LANDING_ZONE_NAME | The name of your Data Landing Zone 
| LOCATION | The region where you want the resources to be deployed
| SYNAPSE_STORAGE_ACCOUNT_NAME | The Synapse Storage Account name 
| SYNAPSE_STORAGE_ACCOUNT_FILE_SYSTEM_NAME | The Synapse Storage Account File System name
| AZURE_RESOURCE_MANAGER_CONNECTION_NAME | The Resource Manager Connection name. More details on how to create the connection name can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) 
| HUB_VNET_ID | The VNet ID from the Data Management Subscription that will be peered with the new VNet deployed inside the Data Landing Zone


Once you save your changes to the file, one last step to complete. Please Update the GitHub Workflow environment variables in <a href="/.github/workflows/dataNodeDeployment.yml">`/.github/workflows/dataNodeDeployment.yml`</a>. 
After completing, the workflow will trigger and run the <a href="/configs/UpdateParameters.ps1">`/configs/UpdateParameters.ps1"` file</a>, which is updating all the variables used in the ARM Templates and you will be ready to deploy the services. 




## Setup for GH Workflows

## Setup for ADO Workflow

### Access Requierements

# Connecting ADO to GitHub to deploy thorugh ADO

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
