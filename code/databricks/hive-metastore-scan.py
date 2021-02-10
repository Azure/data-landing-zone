# Databricks notebook source

# Install the required libraries
dbutils.library.installPyPI("pyapacheatlas")
dbutils.library.restartPython()

# Connect to Purview Account
import json
import os
from pyapacheatlas.auth import ServicePrincipalAuthentication
from pyapacheatlas.core import PurviewClient, AtlasEntity, AtlasProcess, TypeCategory
from pyapacheatlas.core.util import GuidTracker
from pyapacheatlas.core.typedef import AtlasAttributeDef, EntityTypeDef, RelationshipTypeDef

# Add your credentials here or set them as environment variables
tenant_id = "72f988bf-86f1-41af-91ab-2d7cd011db47"
client_id = "634f564f-ef8f-4beb-be61-baf0b19dc84b"
client_secret = "t1h7aLacJ.TsT-GWlxaq_769FD5yJBc--8"
purview_account_name = "hapurview"

oauth = ServicePrincipalAuthentication(
        tenant_id=os.environ.get("TENANT_ID", tenant_id),
        client_id=os.environ.get("CLIENT_ID", client_id),
        client_secret=os.environ.get("CLIENT_SECRET", client_secret)
    )
client = PurviewClient(
    account_name = os.environ.get("PURVIEW_NAME", purview_account_name),
    authentication=oauth
)
guid = GuidTracker()

# COMMAND ----------

# Set up type definitions
type_spark_df = EntityTypeDef(
  name="databricks_table",
  attributeDefs=[
    AtlasAttributeDef(name="format")
  ],
  superTypes = ["DataSet"],
  options = {"schemaElementAttribute":"columns"}
 )
type_spark_columns = EntityTypeDef(
  name="databricks_table_column",
  attributeDefs=[
    AtlasAttributeDef(name="data_type")
  ],
  superTypes = ["DataSet"],
)
type_spark_job = EntityTypeDef(
  name="databricks_job_process",
  attributeDefs=[
    AtlasAttributeDef(name="job_type",isOptional=False),
    AtlasAttributeDef(name="schedule",defaultValue="adHoc")
  ],
  superTypes = ["Process"]
)

spark_column_to_df_relationship = RelationshipTypeDef(
  name="databricks_table_to_columns",
  relationshipCategory="COMPOSITION",
  endDef1={
          "type": "databricks_table",
          "name": "columns",
          "isContainer": True,
          "cardinality": "SET",
          "isLegacyAttribute": False
      },
  endDef2={
          "type": "databricks_table_column",
          "name": "dataframe",
          "isContainer": False,
          "cardinality": "SINGLE",
          "isLegacyAttribute": False
      }
)

typedef_results = client.upload_typedefs(
  entityDefs = [type_spark_df, type_spark_columns, type_spark_job ],
  relationshipDefs = [spark_column_to_df_relationship],
  force_update=True)
#print(typedef_results)

# COMMAND ----------

db_cluster_name = spark.conf.get("spark.databricks.clusterUsageTags.clusterName")
notebook_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()

# Let's look at the tables first.

# Fetch existing databricks tables in Purview using search and filter.
existing_tables = []
filter_setup = {"typeName": "databricks_table", "includeSubTypes": True}
search = client.search_entities("*", search_filter=filter_setup)

for q in search:
    existing_tables.append(q["name"])

# Fetch incoming tables.
all_tbls = spark.sql("SHOW TABLES")
incoming_tables = all_tbls.select("tableName").rdd.flatMap(lambda x: x).collect()

print("- Tables processed")
print("-- Incoming tables from Databricks: ", incoming_tables)
print("-- Existing tables in Purview: ", existing_tables)

# Removed deleted or renamed tables from Purview.
for t in existing_tables:
  if t not in incoming_tables:
    print("Deleted table in Purview: ", t)
    table_guid = client.get_entity(
            qualifiedName = "pyapacheatlas://"+t,
            typeName="databricks_table"
        )["entities"][0]
    #print(json.dumps(table_guid["guid"], indent=2))
    client.delete_entity(guid=table_guid["guid"])

# Now let's look at the columns.

for each_table in incoming_tables:
  # Let's get the columns for the table.
  just_cols = spark.sql("SHOW COLUMNS IN {}".format(each_table))
  
  # And some more details, we'll need this later.
  describe_table = spark.sql("DESCRIBE TABLE {}".format(each_table))
  #describe_table.show()
  
  # Create an asset i.e. Databricks Table for the input data frame.
  atlas_input_df = AtlasEntity(
    name = each_table,
    qualified_name = "pyapacheatlas://"+each_table,
    typeName="databricks_table",
    guid=guid.get_guid(),
  )

  # Create a process that represents our notebook and has our input
  # dataframe as one of the inputs.
  process = AtlasProcess(
    name="demo_cluster"+notebook_path,
    qualified_name = "pyapacheatlas://"+db_cluster_name+notebook_path,
    typeName="databricks_job_process",
    guid=guid.get_guid(),
    attributes = {"job_type":"notebook"},
    inputs = [atlas_input_df],
    outputs = [] # If any, not needed for our purposes.
  )
  
  # Iterate over the input data frame's columns and create them
  table_columns = just_cols.select("col_name").rdd.flatMap(lambda x: x).collect()
  #print("table_columns: ", table_columns)
  incoming_columns = []
  atlas_input_df_columns = []
  for c in table_columns:
    # Get the data type for this column
    column_data_type = describe_table.filter("col_name == '{}'".format(c)).select("data_type").rdd.flatMap(lambda x: x).collect()
    #print("column_data_type: ", column_data_type)
    # Moving on
    temp_column = AtlasEntity(
      name = c,
      typeName = "databricks_table_column",
      qualified_name = "pyapacheatlas://"+each_table+"#"+c,
      guid=guid.get_guid(),
      attributes = {"data_type": column_data_type[0]},
      relationshipAttributes = {"dataframe":atlas_input_df.to_json(minimum=True)}
    )
    incoming_columns.append(c)
    atlas_input_df_columns.append(temp_column)
  
  # Fetch existing columns for the asset if it
  # already exists, this would be a rescan scenario.
  existing_columns = []
  deleted_columns = []
  if each_table in existing_tables:
    purview_columns = client.get_entity(
          qualifiedName = "pyapacheatlas://"+each_table,
          typeName="databricks_table"
      )["entities"][0]["relationshipAttributes"]

    # Get the names of all the existing columns for
    # the asset in Purview if they exist.
    for each_column in purview_columns["columns"]:
      existing_columns.append(each_column["displayText"])

    # Compare the two sets of columns and identify the 
    # ones that have been renamed or deleted.
    columns_diff = list(set(incoming_columns)^set(existing_columns))

    # Identify columns which were deleted, and not renamed.
    for no_change in columns_diff:
      if no_change in existing_columns:
        #print("Not a name_change: ", no_change)
        deleted_columns.append(no_change)

    # Delete all columns in Purview that were removed in the source.
    if set(deleted_columns).issubset(set(existing_columns)):  
      for the_deleted_column in deleted_columns:  
        #print("Deleted column: ", the_deleted_column)
        column_guid = client.get_entity(
                qualifiedName = "pyapacheatlas://"+each_table+"#"+the_deleted_column,
                typeName="databricks_table_column"
            )["entities"][0]
        client.delete_entity(guid=column_guid["guid"])
        
    print("- Table exists in Purview")
    print("-- each_table: ", each_table)
    print("-- incoming_columns: ", incoming_columns)
    print("-- existing_columns: ", existing_columns)
    print("-- deleted_columns: ", deleted_columns)
  else:
    print("- New table asset created in Purview: ", each_table)
 
  # Prepare all the newly created entities as a batch.
  batch = [process, atlas_input_df] + atlas_input_df_columns
  
  # Upload all newly created entities!
  client.upload_entities(batch=batch) 