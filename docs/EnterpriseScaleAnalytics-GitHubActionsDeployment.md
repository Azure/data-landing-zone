# Data Landing Zone - GitHub Action Deployment

In the previous step we have generated a JSON output similar to the following, which will be required in the next steps:

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  (...)
}
```

## Adding Secrets to GitHub respository

If you want to use GitHub Actions for deploying the resources, add the JSON output as a [repository secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository) with the name `AZURE_CREDENTIALS` in your GitHub repository:

![GitHub Secrets](/docs/images/AzureCredentialsGH.png)

To do so, execute the following steps:

1. On GitHub, navigate to the main page of the repository.
2. Under your repository name, click on the **Settings** tab.
3. In the left sidebar, click **Secrets**.
4. Click **New repository secret**.
5. Type the name `AZURE_CREDENTIALS` for your secret in the Name input box.
6. Enter the JSON output from above as value for your secret.
7. Click **Add secret**.

## Update Parameters

In order to deploy the Infrastructure as Code (IaC) templates to the desired Azure subscription, you will need to modify some parameters in the forked repository. Therefore, **this step should not be skipped for neither Azure DevOps/GitHub options**. There are two files that require updates:

- `.github/workflows/dataLandingZoneDeployment.yml` and
- `infra/params.dev.json`.

Update these files in a seperate branch and then merge via Pull Request to trigger the initial deployment.

### Configure `dataLandingZoneDeployment.yml`

To begin, please open [.github/workflows/dataLandingZoneDeployment.yml](/.github/workflows/dataLandingZoneDeployment.yml). In this file you need to update the environment variables section. Just click on [.github/workflows/dataLandingZoneDeployment.yml](/.github/workflows/dataLandingZoneDeployment.yml) and edit the following section:

```yaml
env:
  AZURE_SUBSCRIPTION_ID: "2150d511-458f-43b9-8691-6819ba2e6c7b" # Update to '{dataLandingZoneSubscriptionId}'
  AZURE_LOCATION: "northeurope"                                 # Update to '{regionName}'
```

The following table explains each of the parameters:

| Parameter                                   | Description  | Sample value |
|:--------------------------------------------|:-------------|:-------------|
| **AZURE_SUBSCRIPTION_ID**                   | Specifies the subscription ID of the Data Landing Zone where all the resources will be deployed | <div style="width: 36ch">`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`</div> |
| **AZURE_LOCATION**                          | Specifies the region where you want the resources to be deployed. Please check [Supported Regions](/docs/EnterpriseScaleAnalytics-Prerequisites.md) | `northeurope` |

### Configure `params.dev.json`

To begin, please open the [infra/params.dev.json](/infra/params.dev.json). In this file you need to update the variable values. Just click on [infra/params.dev.json](/infra/params.dev.json) and edit the values. An explanation of the values is given in the table below:

| Parameter                                | Description  | Sample value |
|:-----------------------------------------|:-------------|:-------------|
| `location`    | Specifies the location for all resources. | `northeurope` |
| `environment` | Specifies the environment of the deployment. | `dev`, `tst` or `prd` |
| `prefix`      | Specifies the prefix for all resources created in this deployment. | `prefi` |
| `tags`        | Specifies the tags that you want to apply to all resources. | {`key`: `value`} |
| `vnetAddressPrefix` | Specifies the address space of the vnet of the Data Landing Zone. | `10.1.0.0/16` |
| `servicesSubnetAddressPrefix` | Specifies the address space of the subnet that is used for general services of the Data Landing Zone. | `10.1.0.0/24` |
| `databricksIntegrationPublicSubnetAddressPrefix` | Specifies the address space of the public subnet that is used for the shared integration Databricks workspace. | `10.1.1.0/24` |
| `databricksIntegrationPrivateSubnetAddressPrefix` | Specifies the address space of the private subnet that is used for the shared integration Databricks workspace. | `10.1.2.0/24` |
| `databricksProductPublicSubnetAddressPrefix` | Specifies the address space of the public subnet that is used for the shared product Databricks workspace. | `10.1.3.0/24` |
| `databricksProductPrivateSubnetAddressPrefix` | Specifies the address space of the private subnet that is used for the shared product Databricks workspace. | `10.1.4.0/24` |
| `powerBiGatewaySubnetAddressPrefix` | Specifies the address space of the subnet that is used for the Power BI Gateway. | `10.1.5.0/24` |
| `dataIntegration001SubnetAddressPrefix` | Specifies the address space of the subnet that is used for Data Integration 001. | `10.1.6.0/24` |
| `dataIntegration002SubnetAddressPrefix` | Specifies the address space of the subnet that is used for Data Integration 002. | `10.1.7.0/24` |
| `dataProduct001SubnetAddressPrefix` | Specifies the address space of the subnet that is used for Data Product 001. | `10.1.8.0/24` |
| `dataProduct002SubnetAddressPrefix` | Specifies the address space of the subnet that is used for Data Product 002. | `10.1.9.0/24` |
| `dataManagementZoneVnetId` | Specifies the resource Id of the vnet in the Data Management Zone. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/virtualNetworks/{vnet-name}` |
| `firewallPrivateIp` | Specifies the private IP address of the central firewall. | `10.0.0.4` |
| `dnsServerAdresses` | Specifies the private IP addresses of the DNS Servers. | `[ 10.0.0.4 ]` |
| `administratorPassword` | Specifies the administrator password of the SQL Servers. Will be automatically set in the workflow. **Leave this value as is.** | `<your-secure-password>` |
| `purviewId` | Specifies the Resource ID of the central Purview instance. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Purview/accounts/{purview-name}` |
| `purviewManagedStorageId` | Specifies the Resource ID of the managed storage of the central purview instance. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Storage/storageAccounts/{storage-account-name}` |
| `purviewManagedEventHubId` | Specifies the Resource ID of the managed event hub of the central purview instance. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.EventHub/namespaces/{eventhub-namespace-name}` |
| `purviewSelfHostedIntegrationRuntimeAuthKey` | Specifies the Auth Key for the Self-hosted integration runtime of Purview. | `<your-purview-shir-auth-key>` |
| `deploySelfHostedIntegrationRuntimes` | Specifies whether the self-hosted integration runtimes should be deployed. This only works, if the pwsh script was uploded and is available. | `true` or `false` |
| `portalDeployment` | Specifies whether the deployment was submitted through the Azure Portal. | `true` or `false` |
| `privateDnsZoneIdKeyVault` | Specifies the Resource ID of the private DNS zone for KeyVault. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net` |
| `privateDnsZoneIdDataFactory` | Specifies the Resource ID of the private DNS zone for Data Factory. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net` |
| `privateDnsZoneIdDataFactoryPortal` | Specifies the Resource ID of the private DNS zone for Data Factory Portal. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.adf.azure.com` |
| `privateDnsZoneIdBlob` | Specifies the Resource ID of the private DNS zone for Blob Storage. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net` |
| `privateDnsZoneIdDfs` | Specifies the Resource ID of the private DNS zone for Datalake Storage. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net` |
| `privateDnsZoneIdSqlServer` | Specifies the Resource ID of the private DNS zone for Sql Server. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net` |
| `privateDnsZoneIdMySqlServer` | Specifies the Resource ID of the private DNS zone for MySql Server. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com` |
| `privateDnsZoneIdEventhubNamespace` | Specifies the Resource ID of the private DNS zone for EventHub Namespaces. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net` |
| `privateDnsZoneIdSynapseDev` | Specifies the Resource ID of the private DNS zone for Synapse Dev. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net` |
| `privateDnsZoneIdSynapseSql` | Specifies the Resource ID of the private DNS zone for Synapse Sql. | `/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net` |

## Merge these changes back to the `main` branch of your repo

After following the instructions and updating the parameters and variables in your repository in a separate branch and opening the pull request, you can merge the pull request back into the `main` branch of your repository by clicking on **Merge pull request**. Finally, you can click on **Delete branch** to clean up your repository. By doing this, you trigger the deployment workflow.

## Follow the workflow deployment

**Congratulations!** You have successfully executed all steps to deploy the template into your environment through GitHub Actions.

Now, you can navigate to the **Actions** tab of the main page of the repository, where you will see a workflow with the name `Data Landing Zone Deployment` running. Click on it to see how it deploys the environment. If you run into any issues, please check the [Known Issues](/docs/EnterpriseScaleAnalytics-KnownIssues.md) first and open an [issue](https://github.com/Azure/data-landing-zone/issues) if you come accross a potential bug in the repository.

>[Previous](/docs/EnterpriseScaleAnalytics-ServicePrincipal.md)
>[Next](/docs/EnterpriseScaleAnalytics-KnownIssues.md)
