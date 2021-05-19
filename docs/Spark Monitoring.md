# Spark Monitoring

> *These are just notes on about the Spark Monitoring application and how the JAR files are loaded.*

- Instead of copying pre-built binaries for the Spark Monitoring solution, the deployment process includes a step that will download the source code from GitHub and build it. This creates the JAR files that are then copied to the DBFS. This is handled in a notebook that is executed whenever a new Databricks workspace is provisioned.
