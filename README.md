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

![Data Landing Zone](./media/datalandingzone.png)

 - A Data Landing Zone has a **network resource group**, which includes services to enable connectivity to on-prem, other clouds and other Azure services. These services include: 
    - **Vnet**, which is peered to the Vnet of the Data Management Subscription as well as to the Vnet of the Azure Platform Vnet
    - **NSGs** for traffic restriction purposes
    - **Route Tables** in order to defined next hopes within the network topology
    - **Network Watcher** 
- A **management resource group**, which should be used for hosting private agents for DevOps or GitHub in order to be able to deploy code on the privately hosted services. 
    - **CI/CD Agents** 
    - 1 **key vault** for storing secrets
- An **integration resource group**, containing: 
    - 1 **artifact storage account**, which will contain the script for creating and deploying SHIR
    - 1 **SHIR** 
    - 1 **Data Factory**
- A **logging resource group**, which will include
    - 1 **log analytics workspace**
    - 1 **key vault**
- A **storage resource group**, for hosting the data lakes of the Data Landing Zone. Three data lakes are recommended to be used per each Data Landing Zone, therefor, we will deploy inside this resource group: 
    - **Raw Data Data Lake**
    - **Curated & Enriched Data Lake**
    - **Workspace Data Lake**
    More details can be found in [].
- A **secure storage resource group**, which will contain separate data lakes for highly confidential data in order to put different isolation boundaries on the network, identity and data layer in place. The structure for this resource group will be the same to the above described **storage resource group**:
    - **Raw Data Data Lake**
    - **Curated & Enriched Data Lake**
    - **Workspace Data Lake**
- An **external resource group**, that will include dedicated storage account in order to be able to retrieve a storage account SAS token or access key in case we ingest data from external sources into the Azure platform: 
    - **Blob Storage A**
- A **metadata resource group**, which will include:
    - 1 Hive Metastore data, for which it will be deployed: 
        - 1 **sql server** 
        - 1 **SQL Database**
    - 1 Data Factory Metastore, for which it will be deployed:
        - 1 **sql server** 
        - 1 **SQL Database**
    - 2 **Key Vaults**, to store secrets required for Azure Data Factory and  Databricks
- A **processing domain resource group**, for storing shared processing engines. Here we will deploy:
    - 1 **Databricks workspace**, for ingestion purposes 
    - 1 **Data Factory**, for ingestion purposes
    - 1 aditional **Event Hub**, used for streaming use cases and essentially requires support for data stream push scenarios
- A **processing product resource group**, which will contain:
    - 1 **Synapse instance**
    - 1 **Databricks workspace**, to be shared across all data product teams and can be used for ad-hoc analysis 


    
# Getting started

## 1. Prerequisites

The following prerequisites are required to make this repository work:
- Azure subscription
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

### Process

### What do parameters mean

# Service Principals

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
