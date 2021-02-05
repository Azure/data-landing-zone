# Enterprise Scale Analytics - Data Landing Zone

**General disclaimer** Please be aware that this template is in public preview. Therefore, expect smaller bugs and issues when working with the solution. Please submit an Issue, if you come across any issues that you would like us to fix.


# Quickstart

| Data Landing Zone |
|:--------------|
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-node%2Fmain%2Fdocs%2Freference%2Fdeploy.dataNode.json)

# Description 
A Data Landing Zone has several layers to enable agility to service the Data Domains under the node. A new Data Landing Zone is always deployed with a standard set of services to enable the entity to start ingesting and analysing data.

### What will be deployed?

By default, all the services which comes unde Data Landing Zone are enabled and you must explicitly disable them if you don't want it to be deployed. 

![Data Landing Zone](./media/datalandingzone.png)

 - A Data Landing Zone has a **network resource group**, which includes services to enable connectivity to on-prem, other clouds and other Azure services. These services include: 
    - **Vnet**, which is peered to the Vnet of the Data Management Subscription as well as to the Vnet of the Azure Platform Vnet
    - **NSGs** for traffic restriction purposes
    - **Route Tables** in order to defined next hopes within the network topology
    - **Network Watcher** - TBC

- One **management resource group**, which should be used for hosting private agents for DevOps or GitHub in order to be able to deploy code on the privately hosted services. 
    - **CI/CD Agents** 
    - **key Vault** for storing secrets

- One **integration resource group**, containing: 
    - 1 **artifact storage account**, which will contain the script for creating and deploying SHIR
    - 1 **SHIR** 
    - 1 **Data Factory**

- One **logging resource group**, which will include
    - 1 **log analytics workspace**
    - 1 **key vault**

- One **storage resource group**, for hosting the data lakes of the Data Landing Zone. Three data lakes are recommended to be used per each Data Landing Zone, therefor, we will deploy inside this resource group: 
    - **Raw Data Data Lake**
    - **Curated & Enriched Data Lake**
    - **Workspace Data Lake**
    More details can be found in [].

- One **secure storage resource group**, which will contain separate data lakes for highly confidential data in order to put different isolation boundaries on the network, identity and data layer in place. The structure for this resource group will be the same to the above described **storage resource group**:
    - **Raw Data Data Lake**
    - **Curated & Enriched Data Lake**
    - **Workspace Data Lake**

- One **external resource group**, that will include dedicated storage account in order to be able to retrieve a storage account SAS token or access key in case we ingest data from external sources into the Azure platform: 
    - **Blob Storage A**

- One **metadata resource group**, which will include:
    - 1 Hive Metastore data, for which it will be deployed: 
        - 1 **sql server A** 
        - 1 **SQL Database A**
    - 1 Data Factory Metastore, for which it will be deployed:
        - 1 **sql server B** 
        - 1 **SQL Database B**
    - 2 **Key Vaults**, to store secrets required for Azure Data Factory and  Databricks

- One **processing domain resource group**, for storing shared processing engines. Here we will deploy:
   
    - 1 **Databricks workspace** - for ingestion purposes 
    - 1 **Data Factory** - for ingestion purposes
    - 1 **Event Hub** - optionally, used for streaming use cases and essentially requires support for data stream push scenarios
    

- One **processing product resource group**, which will contain:
    - 1 **Synapse instance**
    - 1 **Databricks workspace** - to be shared across all data product teams and can be used for ad-hoc analysis 


    
# Getting started

### 1. Prerequisites

The following prerequisites are required to make this repository work:
- Azure subscription
- Contributor access to the Azure subscription

If you don’t have an Azure subscription, create a free account before you begin. Try the [free version of Azure](https://azure.microsoft.com/en-in/free/).


### 2. Create repository from a template

### 3. Setting up the required secrets

# Parameter Update Process

### Process

### What do parameters mean

# Service Principals

### Setup for GH Workflows

### Setup for ADO Workflow

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
