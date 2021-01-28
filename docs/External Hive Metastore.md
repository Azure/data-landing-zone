# External Hive Metastore

> *These are just notes on how the external Hive metastore is configured for Azure Databricks.
> This should be incorporated more formally into the documentation.*

* Hive metastore settings are changed by a global init script.  This script is managed by the new
[Global Init Scripts](https://docs.databricks.com/clusters/init-scripts.html#global-init-scripts) API.
As of January, 2021, the new global init scripts API is in public preview.  However, Microsoft's official
position is that public preview features in Azure Databricks are ready for production environments and
are supported by the Support Team.  For more details, see:
[Azure Databricks Preview Releases](https://docs.microsoft.com/en-us/azure/databricks/release-notes/release-types)

* This solution uses [Azure Database for MySQL](https://azure.microsoft.com/en-us/services/mysql/) to store the
Hive metastore.  This database was chosen because it is more cost effective and because MySQL is highly compatible
with Hive.
