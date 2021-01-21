#!/bin/sh

# Copy metastore jars from DBFS to the local FileSystem of every node.
mkdir -p /databricks/hive_metastore_jars
chmod 755 /databricks/hive_metastore_jars
cp -r /dbfs/databricks/hive-metastore-jars /databricks/hive_metastore_jars
