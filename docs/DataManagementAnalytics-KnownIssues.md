# Data Landing Zone - Known Issues

## Error: MissingSubscriptionRegistration

**Error Message:**

```sh
ERROR: Deployment failed. Correlation ID: ***
  "error": ***
    "code": "MissingSubscriptionRegistration",
    "message": "The subscription is not registered to use namespace 'Microsoft.DocumentDB'. See https://aka.ms/rps-not-found for how to register subscriptions.",
    "details": [
      ***
        "code": "MissingSubscriptionRegistration",
        "target": "Microsoft.DocumentDB",
        "message": "The subscription is not registered to use namespace 'Microsoft.DocumentDB'. See https://aka.ms/rps-not-found for how to register subscriptions."
```

**Solution:**

This error message appears, in case during the deployment it tries to create a type of resource which has never been deployed before inside the subscription. We recommend to check prior the deployment whether the required resource providers are registered for your subscription and if needed, register them through the `Azure Portal`, `Azure Powershell` or `Azure CLI` as mentioned [here](https://docs.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types).

## Error: ProvisioningDisabled

**Error Message:**

```sh
ERROR: Deployment failed. Correlation ID: ***
    "error": ***
        "code": "DeploymentFailed",
        "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.",
        "details": [
          ***
            "code": "ProvisioningDisabled",
            "message": "This subscription is restricted from provisioning MySQL servers in this region. Please choose a different region or open a support request with service and subscription limits (quotas) issue type."
```

**Solution:**

This error message appears when during the deployment it tries to create a MySql/SQL Database/Other Services but the subscription is restricted from provisioning that specific resource at that specific region. We recommend to request subscription quota increase through a support request, or to deploy to a different region.

>[Previous (Option (a) GitHub Actions)](/docs/DataManagementAnalytics-GitHubActionsDeployment.md)
>[Previous (Option (b) Azure DevOps)](/docs/DataManagementAnalytics-AzureDevOpsDeployment.md)
