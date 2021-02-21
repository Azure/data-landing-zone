#!/bin/sh

# Copy metastore jars from DBFS to the local FileSystem of every node.
mkdir -p /databricks/hive_metastore_jars
chmod 755 /databricks/hive_metastore_jars
cp -r /dbfs/databricks/hive-metastore-jars /databricks/hive_metastore_jars

# Loads environment variables to determine the correct JDBC driver to use.
source /etc/environment

# Define variables for the spark configs
SQL_CONNECTION_STRING=$SQL_CONNECTION_STRING
SQL_USERNAME=$SQL_USERNAME
SQL_PASSWORD=$SQL_PASSWORD
HIVE_VERSION=$HIVE_VERSION
echo "Using Hive version: ${HIVE_VERSION}"

# Quoting the label (i.e. EOF) with single quotes to disable variable interpolation.
echo "Creating Spark Config File"
cat > /databricks/driver/conf/00-custom-spark.conf << EOF
[driver] {
    # Hive specific configuration options.
    # spark.hadoop prefix is added to make sure these Hive specific options will propagate to the metastore client.
    # JDBC connect string for a JDBC metastore
    "spark.hadoop.javax.jdo.option.ConnectionURL" = "${SQL_CONNECTION_STRING}"
    
    # Username to use against metastore database
    "spark.hadoop.javax.jdo.option.ConnectionUserName" = "${SQL_USERNAME}"
    
    # Password to use against metastore database
    "spark.hadoop.javax.jdo.option.ConnectionPassword" = "${SQL_PASSWORD}"
    
    # Driver class name for a JDBC metastore
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" = "org.mariadb.jdbc.Driver"
    
    # Spark specific configuration options
    "spark.sql.hive.metastore.version" = "${HIVE_VERSION}"
    # Skip this one if <hive-version> is 0.13.x.
    "spark.sql.hive.metastore.jars" = "/databricks/hive_metastore_jars/*"

    # Datanucleus parameters
    "spark.hadoop.hive.metastore.schema.verification" = "false"
    "spark.hadoop.datanucleus.schema.autoCreateAll" = "true"
}
EOF
