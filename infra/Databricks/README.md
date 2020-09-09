# Databricks Hive Metastore configuration

Set the following spark configuration:

```bash
spark.hadoop.javax.jdo.option.ConnectionURL jdbc:sqlserver://<your-sql-server-name>.database.windows.net:1433;database=<your-sql-database-name>;user=<your-sql-server-username>@<your-sql-server-name>;password=<your-sql-server-password>;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;
spark.hadoop.javax.jdo.option.ConnectionUserName <your-sql-server-username>
spark.hadoop.javax.jdo.option.ConnectionPassword <your-sql-server-password>
spark.hadoop.javax.jdo.option.ConnectionDriverName com.microsoft.sqlserver.jdbc.SQLServerDriver
spark.sql.hive.metastore.version 1.2.1
spark.sql.hive.metastore.jars builtin
datanucleus.autoCreateSchema true
datanucleus.fixedDatastore false
```

Test the metastore

```sql
%sql

CREATE TABLE Persons (
    PersonID int,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
);
```

```sql
%sql

show tables;
```

Databricks runtime versions working with Hive Metastore version 1.2.1:
* Databricks Runtime Version 5.5 LTS
* Databricks Runtime Version 6.6 (includes Apache Spark 2.4.5, Scala 2.11)

Newer Databricks runtime versions (7.X) don't work with any Hive Metastore version, if `spark.sql.hive.metastore.jars` is set to `builtin`.
Also, none of the Databricks versions work with a Hive Metastore version higher than 1.2.1, if `spark.sql.hive.metastore.jars` is set to `builtin`.
What we would like to achieve is, that we don't have to lock the user into using a specific Databricks runtime version, while also automatically attaching all Databricks clusters to the external Hive metastore. This could potentielly be achieved if we execute an init script in each of the clusters through cluster policies and pull the correct jars based on the selected Databricks runtime version.
