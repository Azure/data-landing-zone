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
cat << 'EOF' > /databricks/driver/conf/00-custom-spark.conf
[driver] {
    # Hive specific configuration options.
    # spark.hadoop prefix is added to make sure these Hive specific options will propagate to the metastore client.
    # JDBC connect string for a JDBC metastore
    "spark.hadoop.javax.jdo.option.ConnectionURL" = "<sql-connection-string>"
    
    # Username to use against metastore database
    "spark.hadoop.javax.jdo.option.ConnectionUserName" = "<sql-username>"
    
    # Password to use against metastore database
    "spark.hadoop.javax.jdo.option.ConnectionPassword" = "<sql-password>"
    
    # Driver class name for a JDBC metastore
    "spark.hadoop.javax.jdo.option.ConnectionDriverName" = "com.mysql.jdbc.Driver"
    
    # Spark specific configuration options
    "spark.sql.hive.metastore.version" = "<hive-version>"
    # Skip this one if <hive-version> is 0.13.x.
    "spark.sql.hive.metastore.jars" = "/databricks/hive_metastore_jars/*"
    # Datanucleus parameters
    datanucleus.autoCreateSchema = "true"
    datanucleus.fixedDatastore = "false"
}
EOF

# REPLACE variables in the spark config file to enable external Hive metastore connection 
echo "Replacing files inside the Spark Config File"
sed -i "s|<sql-connection-string>|${SQL_CONNECTION_STRING}|g" /databricks/driver/conf/00-custom-spark.conf
sed -i "s|<sql-username>|${SQL_USERNAME}|g" /databricks/driver/conf/00-custom-spark.conf
sed -i "s|<sql-password>|${SQL_PASSWORD}|g" /databricks/driver/conf/00-custom-spark.conf
sed -i "s|<hive-version>|${HIVE_VERSION}|g" /databricks/driver/conf/00-custom-spark.conf
