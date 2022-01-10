# Data Landing Zone - Prerequisites

This template repsitory contains all templates to deploy the Data Landing Zone of the Data Management & Analytics architecture. The Data Landing Zone is a logical construct and a unit of scale in the Data Management & Analytics architecture that enables data retention and execution of data workloads for generating insights and value with data.

## What will be deployed?

By navigating through the deployment steps, you will deploy the folowing setup in a subscription:

> **Note:** Before deploying the resources, we recommend to check registration status of the required resource providers in your subscription. For more information, see [Resource providers for Azure services](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

![Data Landing Zone](/docs/images/DataLandingZone.png)

The deployment and code artifacts include the following services:

- [Virtual Network](https://docs.microsoft.com/azure/virtual-network/virtual-networks-overview)
- [Network Security Groups](https://docs.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Route Tables](https://docs.microsoft.com/azure/virtual-network/virtual-networks-udr-overview)
- [Key Vault](https://docs.microsoft.com/azure/key-vault/general)
- [Storage Account](https://docs.microsoft.com/azure/storage/common/storage-account-overview)
- [Data Lake Storage Gen2](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)
- [Data Factory](https://docs.microsoft.com/azure/data-factory/)
- [Self-Hosted Integration Runtime](https://docs.microsoft.com/azure/data-factory/create-self-hosted-integration-runtime)
- [Log Analytics](https://docs.microsoft.com/azure/azure-monitor/learn/quick-create-workspace)
- [SQL Server](https://docs.microsoft.com/sql/sql-server/?view=sql-server-ver15)
- [SQL Database](https://docs.microsoft.com/azure/azure-sql/database/)
- [Synapse Workspace](https://docs.microsoft.com/azure/synapse-analytics/)
- [Databricks](https://docs.microsoft.com/azure/databricks/)
- [Event Hub](https://docs.microsoft.com/azure/event-hubs/)

## Code Structure

To help you more quickly understand the structure of the repository, here is an overview of what the respective folders contain:

| File/folder                   | Description                                |
| ----------------------------- | ------------------------------------------ |
| `.ado/workflows`              | Folder for ADO workflows. The `dataLandingZoneDeployment.yml` workflow shows the steps for an end-to-end deployment of the architecture. |
| `.github/workflows`           | Folder for GitHub workflows. The `dataLandingZoneDeployment.yml` workflow shows the steps for an end-to-end deployment of the architecture. |
| `code`                        | Sample password generation script that will be run in the deployment workflow for resources that require a password during the deployment. |
| `docs`                        | Resources for this README.                 |
| `infra`                       | Folder containing all the ARM and Bicep templates for each of the resources that will be deployed. |
| `CODE_OF_CONDUCT.md`          | Microsoft Open Source Code of Conduct.     |
| `LICENSE`                     | The license for the sample.                |
| `README.md`                   | This README file.                          |
| `SECURITY.md`                 | Microsoft Security README.                 |

## Supported Regions

For now, we are recommending to select one of the regions mentioned below. The list of regions is limited for now due to the fact that not all services and features are available in all regions. This is mostly related to the fact that we are recommending to leverage at least the zone-redundant storage replication option for all your central Data Lakes in the Data Landing Zones. Since zone-redundant storage is not available in all regions, we are limiting the regions in the Deploy to Azure experience. If you are planning to deploy the Data Management Landing Zone and Data Landing Zone to a region that is not listed below, then please change the setting in the corresponding bicep files in this repository. Deployment has been tested in the following regions:

- (Africa) South Africa North
- (Asia Pacific) Australia East
- (Asia Pacific) Central India
- (Asia Pacific) Japan East
- (Asia Pacific) Southeast Asia
- (Asia Pacific) South India
- (Canada) Canada Central
- (Europe) France Central
- (Europe) Germany West Central
- (Europe) North Europe
- (Europe) UK South
- (Europe) West Europe
- (South America) Brazil South
- (US) Central US
- (US) East US
- (US) East US 2
- (US) South Central US
- (US) West Central US
- (US) West US 2

**Please open a pull request if you want to deploy the artifacts into a region that is not listed above.**

## Prerequisites

> **Note:** Please make sure you have successfully deployed a [Data Management Landing Zone](https://github.com/Azure/data-management-zone). The Data Landing Zone relies on the Private DNS Zones that are deployed in the Data Management Template. If you have Private DNS Zones deployed elsewhere, you can also point to these. If you do not have the Private DNS Zones deployed for the respective services, this template deployment will fail.

Before we start with the deployment, please make sure that you have the following available:

- A **Data Management Landing Zone** deployed. For more information, check the [Data Management Landing Zone](https://github.com/Azure/data-management-zone) repository.
- An Azure subscription. If you don't have an Azure subscription, [create your Azure free account today](https://azure.microsoft.com/free/).
- [User Access Administrator](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#user-access-administrator) or [Owner](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#owner) access to the subscription to be able to create a service principal and role assignments for it.
- For the deployment, please choose one of the **Supported Regions**.

## Deployment

Now you have two options for the deployment of the Data Landing Zone:

1. Deploy to Azure Button
2. GitHub Actions or Azure DevOps Pipelines

To use the Deploy to Azure Button, please click on the button below:

| Reference implementation   | Description | Deploy to Azure |
|:---------------------------|:------------|:----------------|
| Data Management & Analytics Scenario | Deploys a Data Management Landing Zone and one or multiple Data Landing Zones all at once. Provides less options than the the individual Data Management Landing Zone and Data Landing Zone deployment options. Helps you to quickly get started and make yourself familiar with the reference design. For more advanced scenarios, please deploy the artifacts individually. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2FdataManagementAnalytics.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-management-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataManagementAnalytics.json) |
| Data Landing Zone          | Deploys a single Data Landing Zone to a subscription. Please deploy a [Data Management Landing Zone](https://github.com/Azure/data-management-zone) first. |[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Finfra%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fdata-landing-zone%2Fmain%2Fdocs%2Freference%2Fportal.dataLandingZone.json) |

Alternatively, click on `Next` to follow the steps required to successfully deploy the Data Landing Zone through GitHub Actions or Azure DevOps.

>[Next](/docs/DataManagementAnalytics-CreateRepository.md)
