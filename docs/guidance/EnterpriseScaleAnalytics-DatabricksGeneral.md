# Data Landing Zone - Databricks

This document provides guidance for Azure Databricks and some of the considerations that organizations must make when setting up and managing Azure Databricks workspaces.

## Enforcing Tags for Cost Management

Cluster tags allow to easily monitor the cost of cloud resources used by various groups in an organization. More information regarding tags can be found [here](https://docs.microsoft.com/en-us/azure/databricks/administration-guide/account-settings/usage-detail-tags-azure#tag-propagation)

> **Note:** By default, Azure Databricks applies the following tags to each cluster: **Vendor**, **Creator**, **ClusterName** and **ClusterId**

In this implementation, **Regex policy** is used in order to enforce cost center tags definition when user creates a new Databricks cluster. As a result, Azure Databricks applies these tags to the cloud resources like VMs and disk volumes associated to the specific cluster.

 In this case the custom policy JSON section will be the following:

```json
     "custom_tags.costCenter": {
        "type": "regex",
        "pattern": "[A-Z]{5}-[0-9]{5}",
        "isOptional": false,
        "hidden": false
    }
```

By setting the value of **"isOptional"** to *false*, it prevents the creation of a cluster without specifying a costCenter with a value which needs to follow the defined pattern ( length of 11 chars, with 5 uppercase chars followed by "-", followed by 5 numbers).

![Defining costCenter tag for Databricks](/docs/images/DefiningCostCenter-DatabricksUX.png)

As a result, when the cluster is created, the VMs provisioned in the Managed Resource Group will have assigned the defined cost tag.

![Showing costCenter tag for Databricks](/docs/images/CostCenterDefined-Portal.png)

## External Hive Metastore

> *These are just notes on how the external Hive metastore is configured for Azure Databricks.
> This should be incorporated more formally into the documentation.*

- Hive metastore settings are changed by a global init script. This script is managed by the new [Global Init Scripts](https://docs.databricks.com/clusters/init-scripts.html#global-init-scripts) API. As of January, 2021, the new global init scripts API is in public preview. However, Microsoft's official position is that public preview features in Azure Databricks are ready for production environments and are supported by the Support Team. For more details, see:
[Azure Databricks Preview Releases](https://docs.microsoft.com/en-us/azure/databricks/release-notes/release-types)

- This solution uses [Azure Database for MySQL](https://azure.microsoft.com/en-us/services/mysql/) to store the Hive metastore. This database was chosen because it is more cost effective and because MySQL is highly compatible with Hive.

## Spark Monitoring

> *These are just notes on about the Spark Monitoring application and how the JAR files are loaded.*

- Instead of copying pre-built binaries for the Spark Monitoring solution, the deployment process includes a step that will download the source code from GitHub and build it. This creates the JAR files that are then copied to the DBFS. This is handled in a notebook that is executed whenever a new Databricks workspace is provisioned.

