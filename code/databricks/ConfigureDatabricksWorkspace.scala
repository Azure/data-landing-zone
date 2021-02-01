// Databricks notebook source
// MAGIC %md
// MAGIC # Configure Databricks Workspace
// MAGIC 
// MAGIC This notebook will take several steps to configure a newly created Databricks workspace within an Enterprise Scale Analytics landing zone.

// COMMAND ----------

// MAGIC %md
// MAGIC ## Retrieve Hive Metastore `.jar` Files
// MAGIC 
// MAGIC Enterprises have the option of installing the desired version of Apache Hive within the Databricks workspace.
// MAGIC 
// MAGIC We will use [Apache Maven](https://maven.apache.org/) to retrieve the necessary `.jar` files.  To begin, we must install Maven on the driver node.  The driver node is an ephemeral Ubuntu Linux VM.
// MAGIC We can use the regular Ubuntu package manager to install Maven.  We don't have to worry about uninstalling the package because the VM will be destroyed when this cluster is terminated.

// COMMAND ----------

// MAGIC %sh
// MAGIC apt-get -y install maven

// COMMAND ----------

// MAGIC %md
// MAGIC Create some directories to hold the binaries that we will download (and clear them out if they already exist).

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /usr/hive-download
// MAGIC rm -rf /usr/hive-download/target

// COMMAND ----------

// MAGIC %md
// MAGIC Unfortunately, Maven won't simply go download all of the `.jar` files for a package.  Instead, we have to use the Project Object Model (POM) to define a "fake" project.  We will specify that the fake project has a
// MAGIC dependency on Hive.  Then we use Maven to build the fake project, and it will download all of the files we need to satisfy our dependency.

// COMMAND ----------

val hiveVersion = dbutils.widgets.get("hive-version");
val hadoopVersion = dbutils.widgets.get("hadoop-version");

val pom = s"""<project>
          |  <modelVersion>4.0.0</modelVersion>
          |  <groupId>com.nothing.fakepom</groupId>
          |  <artifactId>fake-pom</artifactId>
          |  <version>1</version>
          |  <dependencies>
          |    <dependency><groupId>org.apache.hive</groupId><artifactId>hive-metastore</artifactId><version>$hiveVersion</version></dependency>
          |    <dependency><groupId>org.apache.hive</groupId><artifactId>hive-exec</artifactId><version>$hiveVersion</version></dependency>
          |    <dependency><groupId>org.apache.hive</groupId><artifactId>hive-common</artifactId><version>$hiveVersion</version></dependency>
          |    <dependency><groupId>org.apache.hive</groupId><artifactId>hive-serde</artifactId><version>$hiveVersion</version></dependency>
          |    <dependency><groupId>org.apache.hadoop</groupId><artifactId>hadoop-client</artifactId><version>$hadoopVersion</version></dependency>
          |    <dependency><groupId>org.mortbay.jetty</groupId><artifactId>jetty-sslengine</artifactId><version>6.1.26</version></dependency>
          |  </dependencies>
          |</project>"""

import java.nio.file.{Paths, Files}
import java.nio.charset.StandardCharsets

Files.write(Paths.get("/usr/hive-download/pom.xml"), pom.getBytes(StandardCharsets.UTF_8))

// COMMAND ----------

// MAGIC %md
// MAGIC Now we tell Maven to build our fake project and download our desired files.

// COMMAND ----------

// MAGIC %sh
// MAGIC cd /usr/hive-download
// MAGIC 
// MAGIC mvn dependency:copy-dependencies

// COMMAND ----------

// MAGIC %sh
// MAGIC ls /usr/hive-download/target/dependency

// COMMAND ----------

// MAGIC %md
// MAGIC Lastly, we copy the `.jar` files retrieved my Maven to the DBFS.  From there, they can be picked up by clusters when they are spun up.

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /dbfs/databricks/hive-metastore-jars
// MAGIC cp /usr/hive-download/target/dependency/* /dbfs/databricks/hive-metastore-jars

// COMMAND ----------

// MAGIC %md
// MAGIC ## Build Application Logging `.jar` Files
// MAGIC 
// MAGIC The [Microsoft Patterns & Practices](https://github.com/mspnp) collection contains a project for [Monitoring Azure Databricks in an Azure Log Analytics Workspace](https://github.com/mspnp/spark-monitoring).
// MAGIC This allows enterprises to centralize storage and analysis of their Spark logs in the Azure Log Analytics service.
// MAGIC 
// MAGIC The following section of the notebook will download the source code for libraries that will send log information to Azure Log Analytics.  Maven will then be used to build the project, and the resulting
// MAGIC `.jar` files will be copied to the DBFS.  From there, clusters in this workspace can load the `.jar` files when they spin up.
// MAGIC 
// MAGIC For the build process, we will need a tool to parse the `pom.xml` file and obtain the build profile names.  We will install the `xmlstarlet` package to accomplish this.

// COMMAND ----------

// MAGIC %sh
// MAGIC apt-get -y install xmlstarlet

// COMMAND ----------

// MAGIC %md
// MAGIC Now we will get the code from GitHub and use Maven to build all of the different profiles defined for the project.

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /usr/app-log-build
// MAGIC cd /usr/app-log-build
// MAGIC 
// MAGIC rm -rf spark-monitoring
// MAGIC git clone https://github.com/mspnp/spark-monitoring.git
// MAGIC cd spark-monitoring/
// MAGIC 
// MAGIC MAVEN_PROFILES=($(xmlstarlet sel -N pom=http://maven.apache.org/POM/4.0.0 -t -v "pom:project/pom:profiles/pom:profile/pom:id" src/pom.xml))
// MAGIC 
// MAGIC for MAVEN_PROFILE in "${MAVEN_PROFILES[@]}"
// MAGIC do
// MAGIC     mvn -f src/pom.xml install -P ${MAVEN_PROFILE}
// MAGIC done

// COMMAND ----------

// MAGIC %md
// MAGIC Now we can copy our freshly built `.jar` files to the DBFS.

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /dbfs/databricks/spark-monitoring
// MAGIC cp /usr/app-log-build/spark-monitoring/src/target/*.jar /dbfs/databricks/spark-monitoring

// COMMAND ----------

// MAGIC %fs
// MAGIC ls /databricks/spark-monitoring/
