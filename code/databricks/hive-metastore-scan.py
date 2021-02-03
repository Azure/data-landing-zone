# Databricks notebook source
# Connect to Purview Account
import os
from pyapacheatlas.auth import ServicePrincipalAuthentication
from pyapacheatlas.core import PurviewClient, AtlasEntity, AtlasProcess, TypeCategory
from pyapacheatlas.core.util import GuidTracker
from pyapacheatlas.core.typedef import AtlasAttributeDef, EntityTypeDef, RelationshipTypeDef

# Add your credentials here or set them as environment variables
tenant_id = "{tenant_id}"
client_id = "{client_id}"
client_secret = "{client_secret}"
purview_account_name = "{purview_account}"

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
print(typedef_results)


# Static path to Hive data in DBFS
dirs = dbutils.fs.ls("dbfs:/user/hive/warehouse")
notebook_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()

# Iterate through all the directories in the Databricks Hive warehouse
# and read in each as a dataframe.
for all_hive in dirs:
  df = spark.read.format("delta").load(all_hive.path)
  oldstr = all_hive.name
  tbl_name = oldstr.replace("/", "") # Remove the slash

  # Create an asset i.e. Databricks Table for the input data frame
  atlas_input_df = AtlasEntity(
    name=tbl_name,
    qualified_name = "pyapacheatlas://"+tbl_name,
    typeName="databricks_table",
    guid=guid.get_guid(),
  )

  # Create a process that represents our notebook and has our input
  # dataframe as one of the inputs.
  process = AtlasProcess(
    name="demo_cluster"+notebook_path,
    qualified_name = "pyapacheatlas://demo_cluster"+notebook_path,
    typeName="databricks_job_process",
    guid=guid.get_guid(),
    attributes = {"job_type":"notebook"},
    inputs = [atlas_input_df],
    outputs = [] # If any, not needed for our purposes.
  )

  # Iterate over the input data frame's columns and create them
  incoming_columns = []
  atlas_input_df_columns = []
  for column in df.schema:
    temp_column = AtlasEntity(
      name = column.name,
      typeName = "databricks_table_column",
      qualified_name = "pyapacheatlas://"+tbl_name+"#"+column.name,
      guid=guid.get_guid(),
      attributes = {"data_type":str(column.dataType)},
      relationshipAttributes = {"dataframe":atlas_input_df.to_json(minimum=True)}
    )
    incoming_columns.append(column.name)
    atlas_input_df_columns.append(temp_column)
  
  # Fetch existing columns for the asset if it
  # already exists, this would be a rescan scenario.
  purview_columns = client.get_entity(
        qualifiedName = "pyapacheatlas://"+tbl_name,
        typeName="databricks_table"
    )["entities"][0]["relationshipAttributes"]
  
  # Get the names of all the existing columns for
  # the asset in Purview if they exist.
  existing_columns = []
  for each_column in purview_columns["columns"]:
    existing_columns.append(each_column["displayText"])

  # Compare the two sets of columns and identify the 
  # ones that have been renamed or deleted.
  columns_diff = list(set(incoming_columns)^set(existing_columns))

  deleted_columns = []
  
  # Identify columns which were deleted, and not renamed.
  for no_change in columns_diff:
    if no_change in existing_columns:
      print("Not a name_change: ", no_change)
      deleted_columns.append(no_change)
              
  # Delete all columns in Purview that were removed in the source.
  if set(deleted_columns).issubset(set(existing_columns)):  
    for the_deleted_column in deleted_columns:  
      print("Deleted column: ", the_deleted_column)
      column_guid = client.get_entity(
              qualifiedName = "pyapacheatlas://"+tbl_name+"#"+the_deleted_column,
              typeName="databricks_table_column"
          )["entities"][0]
      client.delete_entity(guid=column_guid["guid"])
 
  # Prepare all the newly created entities as a batch.
  batch = [process, atlas_input_df] + atlas_input_df_columns
  
  # Upload all newly created entities!
  client.upload_entities(batch=batch)
  
  print("----------------------------------------")
  print("incoming: ", incoming_columns)
  print("columns_diff: ", columns_diff)
  print("existing_columns: ", existing_columns)
  print("deleted_columns: ", deleted_columns)
  print("----------------------------------------")
