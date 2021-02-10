# Required Access for Service Principal

https://docs.microsoft.com/en-us/graph/application-provisioning-configure-api?view=graph-rest-1.0&tabs=http
director.readwrite.all, application.readwrite.ownedby

1. Instantiate Application

Rights: Application.ReadWrite.All, Directory.ReadWrite.All
Link: https://docs.microsoft.com/en-us/graph/api/applicationtemplate-instantiate?tabs=http&view=graph-rest-beta

2. Create the provisioning job based on the template

Rights: TBD
Link: https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationtemplate-list?tabs=http&view=graph-rest-beta

3. Create the provisioning job

Rights: TBD
Link: https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-post?tabs=http&view=graph-rest-beta

4. Validate Credentials

Rights: TBD
Link: https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-validatecredentials?tabs=http&view=graph-rest-beta

5. Save your credentials

Rights: TBD
Link: TBD

6. Start the provisioning job

Rights: TBD
Link: https://docs.microsoft.com/en-us/graph/api/synchronization-synchronizationjob-start?tabs=http&view=graph-rest-beta