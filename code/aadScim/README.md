# Required Access for Service Principal for AAD SCIM automation for Databricks

[Link](https://docs.microsoft.com/en-us/graph/application-provisioning-configure-api?view=graph-rest-1.0&tabs=http)
Directory.ReadWrite.All, Application.ReadWrite.OwnedBy

1. Instantiate Application

Rights: Application.ReadWrite.All, Directory.ReadWrite.All
Link: [Link](https://docs.microsoft.com/en-us/graph/api/applicationtemplate-instantiate?tabs=http&view=graph-rest-beta)

2. Create the provisioning job based on the template

Rights: Application.ReadWrite.OwnedBy, Directory.ReadWrite.All
Link: [Link](https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationtemplate-list?tabs=http&view=graph-rest-beta)

3. Create the provisioning job

Rights: Application.ReadWrite.OwnedBy, Directory.ReadWrite.All
Link: [Link](https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-post?tabs=http&view=graph-rest-beta)

4. Validate Credentials

Rights: Application.ReadWrite.OwnedBy, Directory.ReadWrite.All
Link: [Link](https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-validatecredentials?tabs=http&view=graph-rest-beta)

5. Save your credentials

Rights: TBD (not defined in the docs)
Link: TBD (not defined in the docs)

6. Start the provisioning job

Rights: Application.ReadWrite.OwnedBy, Directory.ReadWrite.All
Link: [Link](https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-start?tabs=http&view=graph-rest-beta)
